const std = @import("std");
const testing = std.testing;
const utils = @import("./comptime_utils.zig");
const Allocator = @import("std").mem.Allocator;

const CountMinSketchCell = struct {
    occurrences: u32,
};

fn CountMinSketch(comptime IdentifierProducingT: type, comptime hash_count: u8, comptime buckets: u16) type {
    utils.check_meth(IdentifierProducingT, "get_id", u32);

    return struct {
        mtx: [hash_count][buckets]CountMinSketchCell,

        const Self = @This();
        const Hash = std.hash.XxHash3;

        fn init() Self {
            var i: u8 = 0;
            var j: u16 = 0;
            var mtx: [hash_count][buckets]CountMinSketchCell = undefined;
            while (i < mtx.len) {
                j = 0;
                while (j < mtx[i].len) {
                    mtx[i][j].occurrences = 0;
                    j += 1;
                }
                i += 1;
            }

            return .{
                .mtx = mtx,
            };
        }

        fn register_occurence(self: *Self, x: IdentifierProducingT) void {
            var i: u8 = 0;
            var j: u16 = 0;
            while (i < self.mtx.len) {
                j = @as(u16, @intCast(Hash.hash(i, std.mem.asBytes(&x.get_id())) % buckets));
                self.mtx[i][j].occurrences += 1;
                i += 1;
            }
        }

        fn get_element_count(self: *Self, x: IdentifierProducingT) u32 {
            var i: u8 = 0;
            var j: u16 = 0;
            var occurrences: u32 = undefined;
            while (i < self.mtx.len) {
                j = @as(u16, @intCast(Hash.hash(i, std.mem.asBytes(&x.get_id())) % buckets));
                const local_occurences = self.mtx[i][j].occurrences;
                occurrences = @min(occurrences, local_occurences);
                i += 1;
            }
            return occurrences;
        }
    };
}

test "Count min sketch test" {
    const S1 = struct {
        value: u32,

        const Self = @This();

        pub fn get_id(self: Self) u32 {
            return self.value;
        }
    };
    var cms = CountMinSketch(S1, 100, 1600).init();

    for (0..2000) |_| {
        cms.register_occurence(S1{ .value = 33 });
    }
    for (0..8000) |_| {
        cms.register_occurence(S1{ .value = 100 });
    }

    //adding for some entropy
    for (1000..4000) |i| {
        cms.register_occurence(S1{ .value = @as(u32, @intCast(i)) });
    }
    const res1 = cms.get_element_count(S1{ .value = 33 });
    const res2 = cms.get_element_count(S1{ .value = 100 });

    try testing.expect(res1 == 2000);
    try testing.expect(res2 == 8000);
}

test "Test Count min sketch limits" {
    const S1 = struct {
        value: u32,

        const Self = @This();

        pub fn get_id(self: Self) u32 {
            return self.value;
        }
    };
    var cms = CountMinSketch(S1, 100, 1600).init();

    for (0..2000) |_| {
        cms.register_occurence(S1{ .value = 33 });
    }
    for (0..8000) |_| {
        cms.register_occurence(S1{ .value = 100 });
    }

    //adding for some entropy
    for (1000..18000) |i| {
        cms.register_occurence(S1{ .value = @as(u32, @intCast(i)) });
    }
    const res1 = cms.get_element_count(S1{ .value = 33 });
    const res2 = cms.get_element_count(S1{ .value = 100 });

    try testing.expect(res1 != 2000);
    try testing.expect(res2 != 8000);
}

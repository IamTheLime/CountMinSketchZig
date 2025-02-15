const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const CountMinSketchCell = struct {
    elements: std.BufSet,
    count_distinct: u32,
};

fn CountMinSketch(comptime hash_count: u8, comptime buckets: u16) type {
    return struct {
        allocator: Allocator,
        hashes: [hash_count]std.hash.XxHash3,
        mtx: [hash_count][buckets]CountMinSketchCell,

        const Self = @This();

        fn init(allocator: Allocator) Self {
            var hash_list: [hash_count]std.hash.XxHash3 = undefined;
            var i: u8 = 0;
            while (i < hash_list.len) {
                hash_list[i] = std.hash.XxHash3.init(i);
                i += 1;
            }

            var mtx: [hash_count][buckets]CountMinSketchCell = undefined;
            var j: u16 = 0;
            while (i < mtx.len) {
                j = 0;
                while (j < mtx[i].len) {
                    mtx[i][j].count_distinct = 0;
                    mtx[i][j].elements = std.BufSet.init(allocator);
                    j += 1;
                }
                i += 1;
            }

            return .{
                .allocator = allocator,
                .hashes = hash_list,
                .mtx = mtx,
            };
        }

        fn deinit(self: *Self) void {
            for (self.mtx) |row| {
                for (row) |val| {
                    self.allocator.destroy(val.elements);
                }
            }
        }
    };
}

test "Count min sketch test" {
    // std.log.warn("here", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cms = CountMinSketch(3, 16).init(allocator);
    defer cms.deinit();

    // std.log.warn("This is cms: {any}", .{cms});
}

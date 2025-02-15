const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const CountMinSketchCell = struct {
    //It will hold all occurrences for the cell,
    //we can hash an elemente again to see occurences
    //of a certain event
    occurrences: u32,
};

fn CountMinSketch(comptime IdentifierProducingT: type, comptime hash_count: u8, comptime buckets: u16) type {
    if (!std.meta.hasMethod(IdentifierProducingT, "get_id")) {
        @compileError("Cannot create CountMinSketch on an item that is unable to return identifier");
    }

    return struct {
        hashes: [hash_count]std.hash.XxHash3,
        mtx: [hash_count][buckets]CountMinSketchCell,

        const Self = @This();

        fn init() Self {
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
                    mtx[i][j].occurrences = 0;
                    j += 1;
                }
                i += 1;
            }

            return .{
                .hashes = hash_list,
                .mtx = mtx,
            };
        }

        fn register_occurence(self: *Self, x: IdentifierProducingT) void {
            var i = 0;
            var j = 0;
            while (i < self.mtx.len) {
                j = self.hashes[i].hash(i, x.get_id()) % buckets;
                self.mtx[i][j].occurrences += 1;

                i += 1;
            }
        }
    };
}

const Whatever = struct {
    value: u32,

    const Self = @This();

    fn get_id(self: *Self) u32 {
        self.value;
    }
};

test "Count min sketch test" {
    // std.log.warn("here", .{});

    const cms = CountMinSketch(Whatever, 3, 16).init();
    std.log.warn("This is cms: {any}", .{cms});
}

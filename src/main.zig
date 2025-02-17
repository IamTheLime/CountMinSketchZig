const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const CountMinSketchCell = struct {
    //It will hold all occurrences for the cell,
    //we can hash an elemente again to see occurences
    //of a certain event
    occurrences: u32,
};

const S1 = struct {
    value: u32,

    const Self = @This();

    pub fn get_id(self: Self) u32 {
        return self.value;
    }
};

fn CountMinSketch(comptime IdentifierProducingT: type, comptime hash_count: u8, comptime buckets: u16) type {

    // Checking that the struct S1 implements all the required parameters
    // TODO: move this into an auxiliary function, potentially comptime utils?
    if (!std.meta.hasMethod(IdentifierProducingT, "get_id")) {
        @compileError("Cannot create CountMinSketch on an item that is unable to return identifier");
    }
    const func = IdentifierProducingT.get_id;
    const FuncType = @TypeOf(func);
    const func_info = @typeInfo(FuncType);

    const return_type = func_info.Fn.return_type orelse {
        @compileError("get_id must have a return type");
    };

    if (return_type != u32) {
        @compileError("get_id must return u32, found '" ++ @typeName(return_type) ++ "'");
    }

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

        fn get_element_count(self: *Self, x: IdentifierProducingT) void {
            var i: u8 = 0;
            var j: u16 = 0;
            while (i < self.mtx.len) {
                j = @as(u16, @intCast(Hash.hash(i, std.mem.asBytes(&x.get_id())) % buckets));
                const occurences = self.mtx[i][j].occurrences;
                std.log.warn("I found occurrence {any}", .{occurences});
                i += 1;
            }
        }
    };
}

test "Count min sketch test" {
    var cms = CountMinSketch(S1, 3, 16).init();
    const whatever = S1{ .value = 33 };
    const whatever1 = S1{ .value = 33 };
    const whatever2 = S1{ .value = 33 };
    const whatever3 = S1{ .value = 33 };
    const whatever4 = S1{ .value = 33 };
    const whatever5 = S1{ .value = 34 };
    const whatever6 = S1{ .value = 33 };
    const whatever7 = S1{ .value = 36 };
    cms.register_occurence(whatever);
    cms.register_occurence(whatever1);
    cms.register_occurence(whatever2);
    cms.register_occurence(whatever3);
    cms.register_occurence(whatever4);
    cms.register_occurence(whatever5);
    cms.register_occurence(whatever6);
    cms.register_occurence(whatever7);
    std.log.warn("Getting occurrences", .{});
    cms.get_element_count(whatever);
}

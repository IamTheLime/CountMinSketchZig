const std = @import("std");

pub fn check_meth(comptime type_ref: type, comptime meth_name: []const u8, comptime expected_ret_type: type) void {
    if (!std.meta.hasMethod(type_ref, meth_name)) {
        @compileError("Cannot create CountMinSketch on an item that is unable to return identifier");
    }
    const func = type_ref.get_id;
    const FuncType = @TypeOf(func);
    const func_info = @typeInfo(FuncType);

    const return_type = func_info.Fn.return_type orelse {
        @compileError("get_id must have a return type");
    };

    if (return_type != expected_ret_type) {
        @compileError("get_id must return u32, found '" ++ @typeName(return_type) ++ "'");
    }
}

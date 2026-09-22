const std = @import("std");
const Chunk = @import("../chunk/chunk.zig").Chunk;

pub const Generator = struct {
    context: *anyopaque,
    vtable: *const VTable,

    /// Generator VTable.
    pub const VTable = struct {
        generate: *const fn (*anyopaque, *Chunk) anyerror!void,
        destroy: *const fn (*anyopaque, std.mem.Allocator) void,
    };

    /// Calls the generator's generate function.
    pub fn generate(self: *const Generator, chunk: *Chunk) !void {
        return self.vtable.generate(self.context, chunk);
    }

    /// Calls the generator's destroy function.
    pub fn destroy(self: *const Generator, allocator: std.mem.Allocator) void {
        self.vtable.destroy(self.context, allocator);
    }
};

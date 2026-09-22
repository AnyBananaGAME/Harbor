const std = @import("std");
const Generator = @import("../generator.zig").Generator;
const Chunk = @import("../../chunk/chunk.zig").Chunk;

pub const SuperFlatGenerator = struct {
    allocator: std.mem.Allocator,
    seed: i64,

    pub fn create(
        allocator: std.mem.Allocator,
        seed: i64,
    ) !Generator {
        const generator = try allocator.create(SuperFlatGenerator);
        generator.* = .{
            .allocator = allocator,
            .seed = seed,
        };

        return .{
            .context = generator,
            .vtable = &.{
                .generate = generate,
                .destroy = destroy,
            },
        };
    }

    /// Generates a super flat chunk.
    fn generate(context: *anyopaque, chunk: *Chunk) anyerror!void {
        const self: *SuperFlatGenerator = @ptrCast(@alignCast(context));
        _ = self;

        const block: u64 = @intCast(@as(u32, @bitCast(@as(i32, -567203660))));

        for (0..16) |x| {
            for (0..16) |z| {
                try chunk.setBlock(.{
                    .x = @floatFromInt(chunk.position.x * 16 + @as(i32, @intCast(x))),
                    .y = 60,
                    .z = @floatFromInt(chunk.position.z * 16 + @as(i32, @intCast(z))),
                }, block);
            }
        }
    }

    fn destroy(context: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *SuperFlatGenerator = @ptrCast(@alignCast(context));
        allocator.destroy(self);
    }
};

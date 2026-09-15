const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("Harbor", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const nethernet = b.dependency("nethernet", .{
        .target = target,
        .optimize = optimize,
    });
    const binary_stream = b.dependency("binarystream", .{
        .target = target,
        .optimize = optimize,
    });
    const protocol = b.dependency("protocol", .{
        .target = target,
        .optimize = optimize,
    });

    module.addImport("NetherNet", nethernet.module("NetherNet"));
    module.addImport("Protocol", protocol.module("Protocol"));
    module.addImport("BinaryStream", binary_stream.module("BinaryStream"));
}

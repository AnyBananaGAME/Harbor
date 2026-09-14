const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const binaryStream = b.dependency("binarystream", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("Protocol", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = false,
    });

    mod.addImport("binarystream", binaryStream.module("BinaryStream"));
}

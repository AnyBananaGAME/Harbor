const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const webrtc = b.dependency("webrtc", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("NetherNet", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    mod.addImport("webrtc", webrtc.module("webrtc"));
}

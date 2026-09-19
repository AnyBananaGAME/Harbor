const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binary_stream = b.dependency("binarystream", .{
        .target = target,
        .optimize = optimize,
    });

    const module = b.addModule("Nbt", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    module.addImport("binarystream", binary_stream.module("BinaryStream"));

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    tests.root_module.addImport("binarystream", binary_stream.module("BinaryStream"));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run NBT tests");
    test_step.dependOn(&run_tests.step);
}

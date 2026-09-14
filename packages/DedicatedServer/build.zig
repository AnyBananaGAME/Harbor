const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nethernet = b.dependency("nethernet", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "DedicatedServer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libcpp = false,
        }),
    });

    exe.root_module.addImport(
        "NetherNet",
        nethernet.module("NetherNet"),
    );
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    if (b.args) |args| {
        run.addArgs(args);
    }

    const run_step = b.step("run", "Run DedicatedServer");
    run_step.dependOn(&run.step);
}

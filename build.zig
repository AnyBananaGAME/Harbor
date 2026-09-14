const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const server = b.dependency("dedicated_server", .{
        .target = target,
        .optimize = optimize,
    });

    const server_exe = server.artifact("DedicatedServer");

    b.installArtifact(server_exe);

    const run = b.addRunArtifact(server_exe);
    run.setCwd(b.path("packages/DedicatedServer"));
    if (b.args) |args| {
        run.addArgs(args);
    }

    const run_step = b.step("run", "Run DedicatedServer");
    run_step.dependOn(&run.step);
}

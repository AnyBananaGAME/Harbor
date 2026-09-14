const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_libdatachannel = b.option(bool, "libdatachannel", "Enable the libdatachannel native backend") orelse true;
    const binaryStream = b.dependency("binarystream", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("NetherNet", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = false,
    });
    if (use_libdatachannel and target.result.abi == .gnu) {
        mod.addIncludePath(b.path("libs/libdatachannel/include"));
        mod.addIncludePath(b.path("libs/libdatachannel/deps/libjuice/include"));
        mod.addSystemIncludePath(.{ .cwd_relative = "C:/msys64/ucrt64/include" });
        mod.addIncludePath(.{ .cwd_relative = "C:/msys64/ucrt64/include/c++/15.2.0" });
        mod.addIncludePath(.{ .cwd_relative = "C:/msys64/ucrt64/include/c++/15.2.0/x86_64-w64-mingw32" });
        mod.addCSourceFile(.{ .file = b.path("native/nethernet_datachannel.cpp"), .flags = &.{ "-std=c++17", "-DRTC_STATIC", "-DRTC_ENABLE_MEDIA=0", "-DRTC_ENABLE_WEBSOCKET=0" } });
        mod.addObjectFile(b.path("libs/libdatachannel/build/libdatachannel.a"));
        mod.addObjectFile(b.path("libs/libdatachannel/build/deps/libjuice/libjuice.a"));
        mod.addObjectFile(b.path("libs/libdatachannel/build/deps/usrsctp/usrsctplib/libusrsctp.a"));
        mod.addLibraryPath(.{ .cwd_relative = "C:/msys64/ucrt64/lib" });
        mod.addObjectFile(.{ .cwd_relative = "C:/msys64/ucrt64/lib/libstdc++.a" });
        mod.addObjectFile(.{ .cwd_relative = "C:/msys64/ucrt64/lib/libmingwex.a" });
        mod.addObjectFile(.{ .cwd_relative = "C:/msys64/ucrt64/lib/libgcc_s.a" });
        mod.linkSystemLibrary("msvcrt", .{});
        mod.linkSystemLibrary("ssl", .{ .use_pkg_config = .no });
        mod.linkSystemLibrary("crypto", .{ .use_pkg_config = .no });
        mod.linkSystemLibrary("ws2_32", .{});
        mod.linkSystemLibrary("bcrypt", .{});
        mod.linkSystemLibrary("iphlpapi", .{});
        mod.linkSystemLibrary("crypt32", .{});
    }
    mod.addImport("binarystream", binaryStream.module("BinaryStream"));
}

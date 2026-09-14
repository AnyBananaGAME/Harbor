const std = @import("std");
const nethernet = @import("NetherNet");

const log = std.log.scoped(.dedicated_server);

fn onNetherNetMessage(_: *nethernet.Server.Session, channel: c_int, data: []const u8) void {
    _ = channel;
    _ = data;
    // log.info("{any}", .{data});
}

pub fn main() !void {
    var threaded = std.Io.Threaded.init(std.heap.smp_allocator, .{});
    defer threaded.deinit();

    var server = nethernet.Server.Server.init(
        threaded.io(),
        std.heap.smp_allocator,
        "127.0.0.1",
        19132,
        onNetherNetMessage,
    );

    log.info("Starting NetherNet server on {s}:{d}", .{ server.bind_address, server.port });
    try server.start("0.0.0.0", "../../.nethernet/files/certificate.pem", "../../.nethernet/files/private-key.pem", "../../.nethernet/files/identity-key.pem");
}

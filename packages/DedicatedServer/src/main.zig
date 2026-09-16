const std = @import("std");
const harbor = @import("Harbor");
const nethernet = harbor.NetherNet;

const log = std.log.scoped(.dedicated_server);

pub fn main(init: std.process.Init) !void {
    var threaded = std.Io.Threaded.init(init.gpa, .{});
    defer threaded.deinit();

    var server = harbor.Server.init(threaded.io(), init.gpa);
    try server.start();

    while (true) threaded.io().sleep(.fromSeconds(60), .awake) catch return;
}

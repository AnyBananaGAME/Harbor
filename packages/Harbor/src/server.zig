const std = @import("std");
const Io = @import("std").Io;

const Logger = std.log.scoped(.dedicated_server);

pub const Server = struct {
    io: Io,
    allocator: std.mem.Allocator,

    pub fn init(
        io: Io,
        allocator: std.mem.Allocator,
    ) Server {
        return .{
            .io = io,
            .allocator = allocator,
        };
    }

    pub fn start(self: *Server) !void {
        _ = self;
        Logger.info("Server started successfully.", .{});
    }
};

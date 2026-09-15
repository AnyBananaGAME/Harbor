const std = @import("std");
const Io = @import("std").Io;

const NetworkManager = @import("./network/manager.zig").NetworkManager;

const Logger = std.log.scoped(.dedicated_server);
pub const Server = struct {
    io: Io,
    allocator: std.mem.Allocator,
    network: NetworkManager = undefined,

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
        self.network = NetworkManager.init(self);
        try self.network.start();

        Logger.info("Server started successfully.", .{});
    }
};

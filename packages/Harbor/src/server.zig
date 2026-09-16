const std = @import("std");
const Io = @import("std").Io;

const NetworkManager = @import("./network/manager.zig").NetworkManager;
const PlayerMap = @import("./player/player-map.zig").PlayerMap;

const Logger = std.log.scoped(.DedicatedServer);
pub const Server = struct {
    io: Io,
    allocator: std.mem.Allocator,
    network: NetworkManager = undefined,
    players: PlayerMap,

    pub fn init(
        io: Io,
        allocator: std.mem.Allocator,
    ) Server {
        return .{
            .io = io,
            .allocator = allocator,
            .players = PlayerMap.init(allocator),
        };
    }

    pub fn deinit(self: *Server) void {
        self.players.deinit();
    }

    pub fn start(self: *Server) !void {
        self.network = NetworkManager.init(self);
        try self.network.start();

        Logger.info("Server started successfully.", .{});
    }
};

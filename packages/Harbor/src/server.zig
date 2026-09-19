const std = @import("std");
const Io = @import("std").Io;

const NetherNet = @import("NetherNet");

const NetworkManager = @import("./network/manager.zig").NetworkManager;
const World = @import("./world/world.zig").World;
const Player = @import("./player/player.zig").Player;

const Logger = std.log.scoped(.DedicatedServer);
pub const Server = struct {
    io: Io,
    allocator: std.mem.Allocator,
    network: NetworkManager = undefined,
    worlds: std.StringHashMapUnmanaged(World),

    /// Initializes the server.
    pub fn init(
        io: Io,
        allocator: std.mem.Allocator,
    ) Server {
        return .{
            .io = io,
            .allocator = allocator,
            .worlds = .empty,
        };
    }

    /// Deinitializes the server.
    /// Frees things like worlds
    pub fn deinit(self: *Server) void {
        for (self.worlds.items) |*world| {
            world.deinit(self.allocator);
        }
        self.worlds.deinit(self.allocator);
    }

    /// Starts the server.
    pub fn start(self: *Server) !void {
        if (self.getWorld("default")) |_| {} else {
            var world = try self.createWorld("default");
            const dimension = try world.createDimension("overworld", .Overworld);
            _ = dimension; // autofix
        }

        self.network = NetworkManager.init(self);
        try self.network.start();

        Logger.info("Server started successfully.", .{});
    }

    /// Creates a new world with the given identifier.
    /// Will return error.WorldAlreadyExists if a world with exact identifier already exists.
    pub fn createWorld(self: *Server, identifier: []const u8) !*World {
        if (self.worlds.get(identifier)) |_| {
            return error.WorldAlreadyExists;
        }

        const world = World.init(self.allocator, identifier);
        try self.worlds.put(self.allocator, identifier, world);

        return self.worlds.getPtr(identifier) orelse unreachable;
    }

    /// Returns the world with the given identifier, if it exists.
    /// Otherwise, returns null.
    pub fn getWorld(self: *Server, identifier: []const u8) ?*World {
        return self.worlds.getPtr(identifier);
    }

    /// Returns the default world.
    pub fn getDefaultWorld(self: *Server) ?*World {
        return self.getWorld("default");
    }

    /// Returns the player with the given username, if the player exists.
    /// Otherwise, returns null.
    pub fn getPlayerByUsername(self: *Server, username: []const u8) ?Player {
        var itterator = self.worlds.iterator();
        while (itterator.next()) |entry| {
            if (entry.value_ptr.players.getByUsername(username)) |player| {
                return player;
            }
        }
        return null;
    }

    /// Returns the player with the given session, if the player exists.
    /// Otherwise, returns null.
    pub fn getPlayerBySession(self: *Server, session: *NetherNet.Session) ?*Player {
        var itterator = self.worlds.iterator();
        while (itterator.next()) |entry| {
            if (entry.value_ptr.players.get(session)) |player| {
                return player;
            }
        }
        return null;
    }

    /// Returns the player with the given xuid, if the player exists.
    /// Otherwise, returns null.
    pub fn getPlayerByXuid(self: *Server, xuid: []const u8) ?Player {
        var itterator = self.worlds.iterator();
        while (itterator.next()) |entry| {
            if (entry.value_ptr.players.getByXuid(xuid)) |player| {
                return player;
            }
        }
        return null;
    }
};

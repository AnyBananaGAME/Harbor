const std = @import("std");
const Io = @import("std").Io;

const NetherNet = @import("NetherNet");

const NetworkManager = @import("./network/manager.zig").NetworkManager;
const World = @import("./world/world.zig").World;
const Player = @import("./player/player.zig").Player;
const GeneratorRegistry = @import("./world/generator/registry.zig").GeneratorRegistry;
const SuperFlatGenerator = @import("./world/generator/flat/root.zig").SuperFlatGenerator;

const Logger = std.log.scoped(.DedicatedServer);
pub const Server = struct {
    io: Io,
    allocator: std.mem.Allocator,
    network: NetworkManager = undefined,

    /// A map of worlds with their identifiers as keys.
    worlds: std.StringHashMapUnmanaged(World),

    /// Generator Registry
    generator_registry: GeneratorRegistry,

    /// Initializes the server.
    pub fn init(
        io: Io,
        allocator: std.mem.Allocator,
    ) Server {
        return .{
            .io = io,
            .allocator = allocator,
            .worlds = .empty,
            .generator_registry = GeneratorRegistry.init(allocator),
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
        // Registers the flat generator.
        try self.generator_registry.register("flat", SuperFlatGenerator.create);

        if (self.getWorld("default")) |_| {} else {
            var world = try self.createWorld("default");
            const generator = try self.generator_registry.create("flat", 0);
            const dimension = try world.createDimension(
                "overworld",
                .Overworld,
                generator,
            );

            const block: u64 = @intCast(@as(u32, @bitCast(@as(i32, -567203660))));
            for (0..16) |x| {
                for (0..16) |z| {
                    try dimension.setBlock(.{
                        .x = @floatFromInt(x),
                        .y = 60,
                        .z = @floatFromInt(z),
                    }, block);
                }
            }
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

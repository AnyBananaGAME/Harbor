const std = @import("std");

const Protocol = @import("Protocol");
const DimensionType = Protocol.Enums.DimensionType;
const PlayerMap = @import("../player/player-map.zig").PlayerMap;
const Dimension = @import("./dimension.zig").Dimension;
const Generator = @import("./generator/generator.zig").Generator;

pub const World = struct {
    /// The allocator that the world instance uses,
    /// It is used for allocating player arrays and other memory.
    allocator: std.mem.Allocator,

    /// The identifier of the world aka a name.
    /// Used to identify the world in leveldb or in game.
    identifier: []const u8,

    /// Map that holds the players in this current world.
    players: PlayerMap,

    dimensions: std.StringHashMapUnmanaged(Dimension),

    /// Create a new instance of a world.
    pub fn init(
        allocator: std.mem.Allocator,
        identifier: []const u8,
    ) World {
        return World{
            .allocator = allocator,
            .identifier = identifier,
            .players = PlayerMap.init(allocator),
            .dimensions = .empty,
        };
    }

    /// Deinitialize the world, frees the memory used by the player map & etc.
    pub fn deinit(self: *World) void {
        var iterator = self.dimensions.valueIterator();
        // No need for an itterator here as the map does it inside itself
        self.players.deinit(self.allocator);

        while (iterator.next()) |dimension| {
            dimension.deinit(self.allocator);
        }

        self.dimensions.deinit(self.allocator);
    }

    /// Get a dimension by its identifier.
    /// will return null if it does not exist.
    pub fn getDimension(self: *World, identifier: []const u8) ?*Dimension {
        return self.dimensions.getPtr(identifier);
    }

    /// Create a new dimension.
    /// will return an error if the dimension already exists.
    /// Will return unreachable if the dimension could not be created.
    /// which should never happen... Unless you are out of RAM?
    pub fn createDimension(
        self: *World,
        identifier: []const u8,
        dimension_type: DimensionType,
        generator: Generator,
    ) !*Dimension {
        if (self.getDimension(identifier)) |_| {
            return error.DimensionAlreadyExists;
        }

        const dimension = try Dimension.init(self.allocator, identifier, dimension_type, generator);
        try self.dimensions.put(self.allocator, identifier, dimension);
        return self.dimensions.getPtr(identifier) orelse unreachable;
    }
};

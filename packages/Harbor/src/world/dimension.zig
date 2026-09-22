const std = @import("std");
const Protocol = @import("Protocol");
const DimensionType = Protocol.Enums.DimensionType;

const ChunkPos = Protocol.Types.ChunkPos;
const Vec3 = Protocol.Types.Vec3;

const Chunk = @import("./chunk/chunk.zig").Chunk;
const Generator = @import("./generator/generator.zig").Generator;
const PlayerMap = @import("../player/player-map.zig").PlayerMap;

pub const BroadcastOptions = struct {
    radius: f32 = 65.0,
};

pub const Dimension = struct {
    /// allocator used in the dimension.
    allocator: std.mem.Allocator,

    /// The identifier of the dimension. aka a name
    identifier: []const u8,

    /// The type of the world. e.g. Overworld, Nether, TheEnd.
    typ: DimensionType,

    /// The chunks of the dimension.
    chunks: std.AutoHashMapUnmanaged(ChunkPos, Chunk),

    /// The generator of the dimension.
    generator: Generator,

    /// Players currently in the dimension.
    players: *PlayerMap,

    /// Initialize a new dimension.
    pub fn init(
        allocator: std.mem.Allocator,
        identifier: []const u8,
        typ: DimensionType,
        generator: Generator,
        players: *PlayerMap,
    ) !Dimension {
        return .{
            .allocator = allocator,
            .identifier = identifier,
            .typ = typ,
            .chunks = .empty,
            .generator = generator,
            .players = players,
        };
    }

    /// Broadcasts a packet to all players within the given radius.
    pub fn broadcast(
        self: *Dimension,
        origin: Vec3,
        packet_id: u32,
        payload: []const u8,
        options: BroadcastOptions,
    ) !void {
        const radius_squared = options.radius * options.radius;
        var iterator = self.players.by_session.valueIterator();

        while (iterator.next()) |player| {
            const delta_x = player.*.actor.position.x - origin.x;
            const delta_y = player.*.actor.position.y - origin.y;
            const delta_z = player.*.actor.position.z - origin.z;
            const distance_squared =
                delta_x * delta_x + delta_y * delta_y + delta_z * delta_z;

            if (distance_squared <= radius_squared)
                try player.*.session.sendReliable(packet_id, payload);
        }
    }

    /// Sets a block at the given position.
    pub fn setBlock(self: *Dimension, pos: Vec3, block: u64) !void {
        const chunk = try self.getOrCreateChunk(.{
            .x = @intFromFloat(@floor(pos.x / 16)),
            .z = @intFromFloat(@floor(pos.z / 16)),
        });

        try chunk.setBlock(pos, block);
    }

    /// Gets or creates a chunk at the given position.
    pub fn getOrCreateChunk(self: *Dimension, pos: ChunkPos) !*Chunk {
        if (self.chunks.getPtr(pos)) |chunk| {
            return chunk;
        }
        var chunk = Chunk.init(self.allocator, pos, self.typ);

        // Generates the chunk based on generators generate function
        try self.generator.generate(&chunk);

        try self.chunks.put(self.allocator, pos, chunk);
        return self.chunks.getPtr(pos) orelse unreachable;
    }
};

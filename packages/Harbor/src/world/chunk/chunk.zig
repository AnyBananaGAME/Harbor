const std = @import("std");
const Protocol = @import("Protocol");
const BinaryStream = @import("BinaryStream");

const ChunkPos = Protocol.Types.ChunkPos;
const Vec3 = Protocol.Types.Vec3;
const SubChunk = @import("sub-chunk.zig").SubChunk;
const BlockState = @import("sub-chunk.zig").BlockState;
const Biome = @import("sub-chunk.zig").Biome;
const Storage = @import("sub-chunk-storage.zig").Storage;

pub const Chunk = struct {
    /// The maximum number of sub-chunks in a chunk.
    pub const MAX_SUB_CHUNKS = 24;

    /// Arena allocator for chunk and its sub chunks.
    arena: std.heap.ArenaAllocator,

    /// The position of the chunk in the world. {x, z}
    position: ChunkPos,

    /// The dimension that owns the chunk.
    dimension: Protocol.Enums.DimensionType,

    /// The sub-chunks in the chunk.
    sub_chunks: [MAX_SUB_CHUNKS]?*SubChunk = .{null} ** MAX_SUB_CHUNKS,

    /// Initializes a new chunk.
    pub fn init(
        allocator: std.mem.Allocator,
        position: ChunkPos,
        dimension: Protocol.Enums.DimensionType,
    ) Chunk {
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .position = position,
            .dimension = dimension,
        };
    }

    /// Deinitializes the chunk and its sub chunks.
    pub fn deinit(self: *Chunk) void {
        self.arena.deinit();
    }

    /// Returns or creates a sub-chunk at the given index.
    pub fn getSubChunk(self: *Chunk, index: usize, version: u8) !*SubChunk {
        if (index >= self.subChunkCount()) return error.SubChunkIndexOutOfRange;
        if (self.sub_chunks[index]) |sub_chunk| return sub_chunk;

        const allocator = self.arena.allocator();
        const sub_chunk = try allocator.create(SubChunk);
        const offset: i32 = if (self.dimension == .Overworld) 4 else 0;
        sub_chunk.* = SubChunk.init(allocator, version, @intCast(@as(i32, @intCast(index)) - offset));
        self.sub_chunks[index] = sub_chunk;
        return sub_chunk;
    }

    /// Sets a block using world coordinates.
    pub fn setBlock(self: *Chunk, position: Vec3, block: u64) !void {
        if (block > std.math.maxInt(BlockState)) return error.BlockIdOutOfRange;

        const world_x = @floor(position.x);
        const world_y = @floor(position.y);
        const world_z = @floor(position.z);

        const local_x: u8 = @intCast(@as(i32, @intFromFloat(
            @mod(world_x - @as(f32, @floatFromInt(self.position.x * 16)), 16),
        )));
        const local_y: u8 = @intCast(@as(i32, @intFromFloat(
            @mod(world_y, 16),
        )));
        const local_z: u8 = @intCast(@as(i32, @intFromFloat(
            @mod(world_z - @as(f32, @floatFromInt(self.position.z * 16)), 16),
        )));

        const world_sub_chunk_index = @divFloor(@as(i32, @intFromFloat(world_y)), 16);
        const sub_chunk_offset: i32 = if (self.dimension == .Overworld) 4 else 0;
        const sub_chunk_index: usize = @intCast(world_sub_chunk_index + sub_chunk_offset);
        const sub_chunk = try self.getSubChunk(sub_chunk_index, 9);
        try sub_chunk.setBlock(local_x, local_y, local_z, @intCast(block));
    }

    /// Serializes the chunk subchunk data.
    pub fn serialize(
        self: *const Chunk,
        stream: *BinaryStream.BinaryStream,
        network_format: bool,
    ) !void {
        const count = self.getSubChunkSendCount();

        if (!network_format) {
            try stream.writeU8(@intCast(count));
        }

        for (self.sub_chunks[0..count], 0..) |sub_chunk, index| {
            if (sub_chunk) |value| {
                try value.serialize(stream, network_format);
            } else {
                try stream.writeU8(9);
                try stream.writeU8(0);
                const offset: i32 = if (self.dimension == .Overworld) 4 else 0;
                try stream.writeI8(@intCast(@as(i32, @intCast(index)) - offset));
            }
        }

        try self.serializeBiomes(stream, network_format);
        try stream.writeU8(0);
        try self.serializeBlockEntities(stream);
    }

    /// Returns the number of sub-chunks sent by the chunk.
    pub fn getSubChunkSendCount(self: *const Chunk) usize {
        var count: usize = 0;
        for (self.sub_chunks[0..self.subChunkCount()], 0..) |sub_chunk, index| {
            if (sub_chunk) |value| {
                if (!value.isEmpty()) count = index + 1;
            }
        }
        return count;
    }

    /// Returns the number of vertical sub-chunks for the chunk dimension.
    pub fn subChunkCount(self: *const Chunk) usize {
        return switch (self.dimension) {
            .Overworld => 24,
            .Nether => 8,
            .TheEnd => 16,
        };
    }

    /// Serializes biomes for the chunk.
    /// Tho this should maybe be inside the storage?
    /// But since bds writes it in a chunk it will be here for now
    fn serializeBiomes(
        self: *const Chunk,
        stream: *BinaryStream.BinaryStream,
        network_format: bool,
    ) !void {
        _ = network_format;
        for (self.sub_chunks[0..self.subChunkCount()]) |sub_chunk| {
            if (sub_chunk) |value| {
                if (value.biomes) |storage| {
                    try storage.writeBiome(stream);
                } else {
                    try Storage(Biome).writeEmptyBiome(stream);
                }
            } else {
                try Storage(Biome).writeEmptyBiome(stream);
            }
        }
    }

    /// Deserializes a chunk using the network sub-chunk and biome layout.
    pub fn deserialize(
        allocator: std.mem.Allocator,
        position: ChunkPos,
        dimension: Protocol.Enums.DimensionType,
        stream: *BinaryStream.BinaryStream,
    ) !Chunk {
        var chunk = Chunk.init(allocator, position, dimension);
        errdefer chunk.deinit();

        var index: usize = 0;
        while (index < chunk.subChunkCount() and stream.offset < stream.bytes.len) {
            const header = stream.bytes[stream.offset];
            if (header != 8 and header != 9) break;
            const sub_chunk = try chunk.arena.allocator().create(SubChunk);
            sub_chunk.* = try SubChunk.deserialize(chunk.arena.allocator(), stream);
            sub_chunk.index = @intCast(index);
            chunk.sub_chunks[index] = sub_chunk;
            index += 1;
        }

        for (chunk.sub_chunks[0..chunk.subChunkCount()]) |sub_chunk| {
            const storage = try Storage(Biome).read(chunk.arena.allocator(), stream);
            if (sub_chunk) |value| value.biomes = storage;
        }

        if (stream.offset < stream.bytes.len) _ = try stream.readU8();
        return chunk;
    }

    /// TODO: Block Actors are not yet supported
    fn serializeBlockEntities(
        self: *const Chunk,
        stream: *BinaryStream.BinaryStream,
    ) !void {
        _ = self;
        _ = stream;
    }
};

const std = @import("std");
const Storage = @import("sub-chunk-storage.zig").Storage;
const BinaryStream = @import("BinaryStream").BinaryStream;

pub const BlockState = u32;
pub const Biome = u32;

pub const SubChunk = struct {
    /// The allocator used by SubChunk
    allocator: std.mem.Allocator,

    /// The version of the chunk.
    version: u8,

    /// The index of the chunk in the world.
    index: i8,

    /// Flags used by the sub-chunk storage format.
    storage_flags: u8 = 0,

    /// The layers of the sub-chunk
    /// First is usually for actual blocks
    /// Second one is usually for state metadata like waterlogged
    layers: [2]?Storage(BlockState) = .{ null, null },

    /// Storage for sub chunk biomes
    /// Also weirdly in BDS source code biomes
    /// are stored in sub chunk but not serialized within the sub chunk
    biomes: ?Storage(Biome) = null,

    /// Initialize a new SubChunk.
    pub fn init(
        allocator: std.mem.Allocator,
        version: u8,
        index: i8,
    ) SubChunk {
        return .{
            .version = version,
            .index = index,
            .allocator = allocator,
        };
    }

    /// Deinitialize the SubChunk.
    pub fn deinit(self: *SubChunk) void {
        for (&self.layers) |*layer| {
            if (layer.*) |*storage| storage.deinit();
        }
        if (self.biomes) |*storage| storage.deinit();
    }

    /// Get the block at the given coordinates.
    pub fn getBlock(self: *const SubChunk, x: u8, y: u8, z: u8) BlockState {
        return if (self.layers[0]) |*storage| storage.get(x, y, z) else 0;
    }

    /// Set the block at the given coordinates.
    pub fn setBlock(self: *SubChunk, x: u8, y: u8, z: u8, value: BlockState) !void {
        if (self.layers[0] == null)
            self.layers[0] = try Storage(BlockState)
                .init(self.allocator, 0);
        try self.layers[0].?.set(x, y, z, value);
    }

    /// Get the biome at the given coordinates.
    pub fn getBiome(self: *const SubChunk, x: u8, y: u8, z: u8) Biome {
        return if (self.biomes) |*storage| storage.get(x, y, z) else 0;
    }

    /// Set the biome at the given coordinates.
    pub fn setBiome(self: *SubChunk, x: u8, y: u8, z: u8, value: Biome) !void {
        if (self.biomes == null) self.biomes =
            try Storage(Biome).init(self.allocator, 0);
        try self.biomes.?.set(x, y, z, value);
    }

    /// Serializes the sub chunk to a binary stream.
    pub fn serialize(self: *const SubChunk, stream: *BinaryStream, network_format: bool) !void {
        _ = network_format;
        const storage_count: u8 = if (self.layers[1] != null)
            2
        else if (self.layers[0] != null)
            1
        else
            0;

        try stream.writeU8(self.version);
        try stream.writeU8(storage_count);
        if (self.version == 9) try stream.writeI8(self.index);

        for (self.layers[0..storage_count]) |layer| {
            if (layer) |storage| {
                try storage.write(stream);
            } else {
                try Storage(BlockState).writeEmptyBlock(stream);
            }
        }
    }

    /// Deserializes a sub chunk from a binary stream.
    pub fn deserialize(allocator: std.mem.Allocator, stream: *BinaryStream) !SubChunk {
        const version = try stream.readU8();
        var storage_count: usize = 1;

        if (version > 7) {
            storage_count = try stream.readU8();

            if (storage_count > 2) {
                return error.TooManyLayers;
            }
        }

        var index: i8 = 0;
        if (version == 9) index = try stream.readI8();

        var sub_chunk = SubChunk.init(allocator, version, index);
        errdefer sub_chunk.deinit();

        for (0..storage_count) |layer| {
            sub_chunk.layers[layer] =
                try Storage(BlockState).read(allocator, stream);
        }

        return sub_chunk;
    }

    /// Returns whether the sub chunk is empty (all layers are null).
    pub fn isEmpty(self: *const SubChunk) bool {
        for (self.layers) |layer| {
            if (layer) |storage| {
                if (!storage.isEmpty()) return false;
            }
        }
        return true;
    }
};

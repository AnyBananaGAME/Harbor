const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;

pub const Width = 16;
pub const Volume: usize = Width * Width * Width;
pub const Bits = [_]u8{ 0, 1, 2, 3, 4, 5, 7, 11 };

pub fn Storage(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Allocator used by the storage.
        allocator: std.mem.Allocator,

        /// Palette of unique values used in the storage.
        palette: std.ArrayListUnmanaged(T) = .empty,

        /// Compressed storage of the chunk data.
        words: []u32 = &.{},

        /// Number of bits per value in the storage.
        bits: u8 = 0,

        /// Uniform value used when the storage is uniform.
        uniform: T,

        /// Initializes a new storage
        pub fn init(
            allocator: std.mem.Allocator,
            value: T,
        ) !Self {
            var self = Self{ .allocator = allocator, .uniform = value };
            try self.palette.append(allocator, value);
            return self;
        }

        /// Deinitializes the storage.
        pub fn deinit(self: *Self) void {
            if (self.words.len != 0) self.allocator.free(self.words);
            self.palette.deinit(self.allocator);
        }

        /// Writes the storage to the stream.
        pub fn write(self: *const Self, stream: *BinaryStream) !void {
            if (!validBits(self.bits))
                return error.InvalidStorageBits;

            try stream.writeU8((self.bits << 1) | 1);

            for (self.words) |word| {
                try stream.writeU32(word, .little);
            }

            try stream.writeZigZag(@intCast(self.palette.items.len));

            for (self.palette.items) |value| {
                try stream.writeZigZag(@bitCast(value));
            }
        }

        /// Writes the biome to the stream.
        pub fn writeBiome(self: *const Self, stream: *BinaryStream) !void {
            if (self.bits == 0) {
                try stream.writeU8(1);
                try stream.writeZigZag(@bitCast(self.palette.items[0]));
                return;
            }

            try self.write(stream);
        }

        /// Writes an empty block to the stream.
        pub fn writeEmptyBlock(stream: *BinaryStream) !void {
            try stream.writeU8(3);
            for (0..wordCount(1)) |_| try stream.writeU32(0, .little);
            try stream.writeZigZag(1);
            try stream.writeZigZag(0);
        }

        /// Writes an empty biome to the stream.
        pub fn writeEmptyBiome(stream: *BinaryStream) !void {
            try stream.writeU8(1);
            try stream.writeZigZag(0);
        }

        /// Reads the storage from the stream.
        pub fn read(allocator: std.mem.Allocator, stream: *BinaryStream) !Self {
            const header = try stream.readU8();
            const bits = header >> 1;
            if (!validBits(bits))
                return error.InvalidStorageHeader;

            var self = Self{ .allocator = allocator, .uniform = 0, .bits = bits };

            if (bits != 0)
                self.words = try allocator.alloc(u32, wordCount(bits));

            errdefer self.deinit();

            for (self.words) |*word|
                word.* = try stream.readU32(.little);

            const palette_count = try stream.readZigZag();
            if (palette_count == 0) return error.EmptyPalette;

            try self.palette.ensureTotalCapacity(
                allocator,
                @intCast(palette_count),
            );

            for (0..@intCast(palette_count)) |_| {
                try self.palette.append(
                    allocator,
                    @bitCast(try stream.readZigZag()),
                );
            }

            self.uniform = self.palette.items[0];
            return self;
        }

        /// Returns the value at the given coordinates.
        pub fn get(self: *const Self, x: u8, y: u8, z: u8) T {
            std.debug.assert(x < Width and y < Width and z < Width);

            if (self.bits == 0) return self.uniform;

            return self.palette.items[
                self.index(x, y, z)
            ];
        }

        /// Returns whether the storage is empty.
        pub fn isEmpty(self: *const Self) bool {
            if (self.bits == 0) return self.uniform == 0;

            for (0..Volume) |index_value| {
                if (self.palette.items[readIndex(self.words, index_value, self.bits)] != 0) {
                    return false;
                }
            }

            return true;
        }

        /// Sets the value at the given coordinates.
        pub fn set(self: *Self, x: u8, y: u8, z: u8, value: T) !void {
            std.debug.assert(x < Width and y < Width and z < Width);

            if (self.bits == 0 and value == self.uniform) return;

            const palette_index = try self.paletteIndex(value);

            if (self.bits == 0) {
                try self.expand(1);
                @memset(self.words, 0);
            } else if (palette_index >= (@as(usize, 1) << @intCast(self.bits))) {
                const new_bits = nextBits(self.bits) orelse
                    return error.PaletteFull;

                try self.expand(new_bits);
            }

            self.writeIndex(
                linearIndex(x, y, z),
                @intCast(palette_index),
            );
        }

        /// Returns the index of the given value in the palette.
        fn paletteIndex(self: *Self, value: T) !usize {
            for (self.palette.items, 0..) |item, palette_index| {
                if (item == value) return palette_index;
            }

            try self.palette.append(self.allocator, value);
            return self.palette.items.len - 1;
        }

        /// Expands the storage to fit in a new number of bits.
        fn expand(self: *Self, new_bits: u8) !void {
            const old_bits = self.bits;
            const old_words = self.words;

            self.words = try self.allocator.alloc(
                u32,
                wordCount(new_bits),
            );

            @memset(self.words, 0);
            self.bits = new_bits;

            if (old_bits != 0) {
                for (0..Volume) |voxel_index| {
                    self.writeIndex(
                        voxel_index,
                        readIndex(old_words, voxel_index, old_bits),
                    );
                }

                self.allocator.free(old_words);
            }
        }

        /// Returns the index of the given voxel in the storage.
        fn index(self: *const Self, x: u8, y: u8, z: u8) usize {
            return readIndex(
                self.words,
                linearIndex(x, y, z),
                self.bits,
            );
        }

        /// Writes a value to the storage at the given index.
        fn writeIndex(self: *Self, index_value: usize, value: u32) void {
            const bit = index_value * self.bits;
            const word = bit / 32;
            const shift = bit % 32;
            const mask = (@as(u64, 1) << @intCast(self.bits)) - 1;

            var pair = @as(u64, self.words[word]);

            if (word + 1 < self.words.len) {
                pair |= @as(u64, self.words[word + 1]) << 32;
            }

            const field = mask << @intCast(shift);

            pair = (pair & ~field) |
                ((@as(u64, value) << @intCast(shift)) & field);

            self.words[word] = @truncate(pair);

            if (word + 1 < self.words.len) {
                self.words[word + 1] = @truncate(pair >> 32);
            }
        }
    };
}

/// linear index function that is based on same BDS function
fn linearIndex(x: u8, y: u8, z: u8) usize {
    return (@as(usize, x) * Width + z) * Width + y;
}

/// read index function that is based on same BDS function
fn readIndex(words: []const u32, index_value: usize, bits: u8) u32 {
    const bit = index_value * bits;
    const word = bit / 32;
    const shift = bit % 32;
    const mask = (@as(u64, 1) << @intCast(bits)) - 1;

    var pair = @as(u64, words[word]);

    if (word + 1 < words.len) {
        pair |= @as(u64, words[word + 1]) << 32;
    }

    return @intCast((pair >> @intCast(shift)) & mask);
}

/// just gets the next available bit count for storage.
fn nextBits(bits: u8) ?u8 {
    for (Bits) |candidate| {
        if (candidate > bits) return candidate;
    }

    return null;
}

/// Gets the word count for a given bit count
fn wordCount(bits: u8) usize {
    return (Volume * bits + 31) / 32;
}

/// Returns whether the bit count is valid for storage.
fn validBits(bits: u8) bool {
    return switch (bits) {
        0, 1, 2, 3, 4, 5, 7, 11 => true,
        else => false,
    };
}

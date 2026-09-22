const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const BlockPos = @import("../types/block-pos.zig").BlockPos;
const ChunkPos = @import("../types/chunk-pos.zig").ChunkPos;

pub const ID: u32 = 121;
pub const MaxServerBuiltChunks = 9216;

const Self = @This();

position: BlockPos,
radius: u32,
server_built_chunks: []const ChunkPos,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    if (self.server_built_chunks.len > MaxServerBuiltChunks)
        return error.TooManyChunks;

    try self.position.write(stream);
    try stream.writeVarUint32(self.radius);
    try stream.writeU32(@intCast(self.server_built_chunks.len), .little);
    for (self.server_built_chunks) |chunk|
        try chunk.write(stream);

    return stream.getBuffer();
}

pub fn deserialize(allocator: std.mem.Allocator, stream: *BinaryStream) !Self {
    const position = try BlockPos.read(stream);
    const radius = try stream.readVarUint32();
    const count = try stream.readU32(.little);

    if (count > MaxServerBuiltChunks)
        return error.TooManyChunks;

    const chunks = try allocator.alloc(ChunkPos, count);
    for (chunks) |*chunk|
        chunk.* = try ChunkPos.read(stream);

    return .{
        .position = position,
        .radius = radius,
        .server_built_chunks = chunks,
    };
}

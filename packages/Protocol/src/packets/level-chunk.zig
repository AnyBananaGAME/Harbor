const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ChunkPos = @import("../types/chunk-pos.zig").ChunkPos;

pub const ID: u32 = 58;
pub const MaximumSubChunksCount = 64;

const Self = @This();

chunk_position: ChunkPos,
dimension_id: i32,
sub_chunks_count: u32,
client_request_sub_chunk_limit: ?i32,
cache_enabled: bool,
cache_metadata_count: u32,
cache_metadata: []const u8,
raw_payload: []const u8,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    if (self.sub_chunks_count > MaximumSubChunksCount)
        return error.TooManySubChunks;

    try self.chunk_position.write(stream);
    try stream.writeVarInt32(self.dimension_id);
    try stream.writeVarUint32(self.sub_chunks_count);
    try stream.writeBool(self.client_request_sub_chunk_limit != null);

    if (self.client_request_sub_chunk_limit) |limit|
        try stream.writeVarInt32(limit);

    try stream.writeBool(self.cache_enabled);
    try stream.writeVarUint32(self.cache_metadata_count);
    try stream.writeBytes(self.cache_metadata);

    try stream.writeVarUint32(@intCast(self.raw_payload.len));
    try stream.writeBytes(self.raw_payload);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    const chunk_position = try ChunkPos.read(stream);
    const dimension_id = try stream.readVarInt32();
    const sub_chunks_count = try stream.readVarUint32();

    if (sub_chunks_count > MaximumSubChunksCount)
        return error.TooManySubChunks;

    const client_request_sub_chunk_limit = if (try stream.readBool())
        try stream.readVarInt32()
    else
        null;

    const cache_enabled = try stream.readBool();
    const cache_metadata_count = try stream.readVarUint32();
    const cache_metadata_length = std.math.mul(
        usize,
        @intCast(cache_metadata_count),
        @sizeOf(u64),
    ) catch return error.MetadataTooLarge;

    const cache_metadata = try stream.readBytes(cache_metadata_length);

    const payload_length = try stream.readVarUint32();
    const raw_payload = try stream.readBytes(payload_length);

    return .{
        .chunk_position = chunk_position,
        .dimension_id = dimension_id,
        .sub_chunks_count = sub_chunks_count,
        .client_request_sub_chunk_limit = client_request_sub_chunk_limit,
        .cache_enabled = cache_enabled,
        .cache_metadata_count = cache_metadata_count,
        .cache_metadata = cache_metadata,
        .raw_payload = raw_payload,
    };
}

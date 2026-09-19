const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 82;

resource_name: []const u8 = "",
chunk_size: u32 = 0,
number_of_chunks: u32 = 0,
file_size: u64 = 0,
file_hash: []const u8 = &.{},
is_premium_pack: bool = false,
pack_type: u8 = 0,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarString(self.resource_name);
    try stream.writeU32(self.chunk_size, .little);
    try stream.writeU32(self.number_of_chunks, .little);
    try stream.writeU64(self.file_size, .little);
    try stream.writeVarUint32(@intCast(self.file_hash.len));
    try stream.writeBytes(self.file_hash);
    try stream.writeBool(self.is_premium_pack);
    try stream.writeU8(self.pack_type);
    return stream.getBuffer();
}

const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 83;

resource_name: []const u8 = "",
chunk_id: u32 = 0,
byte_offset: u64 = 0,
chunk_data: []const u8 = &.{},

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarString(self.resource_name);
    try stream.writeU32(self.chunk_id, .little);
    try stream.writeU64(self.byte_offset, .little);
    try stream.writeVarUint32(@intCast(self.chunk_data.len));
    try stream.writeBytes(self.chunk_data);
    return stream.getBuffer();
}

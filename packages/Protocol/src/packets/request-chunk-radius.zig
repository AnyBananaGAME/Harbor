const BinaryStream = @import("binarystream").BinaryStream;

pub const ID: u32 = 69;

const Self = @This();

chunk_radius: i32,
max_chunk_radius: u8,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarInt32(self.chunk_radius);
    try stream.writeU8(self.max_chunk_radius);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    return .{
        .chunk_radius = try stream.readVarInt32(),
        .max_chunk_radius = try stream.readU8(),
    };
}

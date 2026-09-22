const BinaryStream = @import("binarystream").BinaryStream;

pub const ID: u32 = 70;

const Self = @This();

chunk_radius: i32,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarInt32(self.chunk_radius);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    return .{ .chunk_radius = try stream.readVarInt32() };
}

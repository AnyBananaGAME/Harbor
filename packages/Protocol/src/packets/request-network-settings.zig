const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 193;

/// The protocol version of the client
/// This is used to determine if the server supports the client's protocol version
protocol: u32,

/// Serialize the packet into a byte array
pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeU32(self.protocol, .big);
    return stream.getBuffer();
}

/// Deserialize the packet from a byte array
pub fn deserialize(stream: *BinaryStream) !Self {
    return .{
        .protocol = try stream.readU32(.big),
    };
}

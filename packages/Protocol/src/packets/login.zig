const BinaryStream = @import("binarystream").BinaryStream;
const ConnectionRequest = @import("../types/connection-request.zig");

const Self = @This();
pub const ID: u32 = 1;

/// The protocol version of the client
/// This is used to determine if the server supports the client's protocol version
protocol: u32,

/// Connection request of the client
connectionRequest: ConnectionRequest,

/// Serialize the packet into a byte array
pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeU32(self.protocol, .big);
    try self.connectionRequest.write(stream);
    return stream.getBuffer();
}

/// Deserialize the packet from a byte array
pub fn deserialize(stream: *BinaryStream) !Self {
    const protocol = try stream.readU32(.big);

    const connectionRequest = try ConnectionRequest.read(stream);

    return .{
        .protocol = protocol,
        .connectionRequest = connectionRequest,
    };
}

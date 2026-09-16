const BinaryStream = @import("binarystream").BinaryStream;
const PlayStatus = @import("../enums/play-status.zig").PlayStatus;

const Self = @This();
pub const ID: u32 = 2;

status: PlayStatus,

/// Serialize the packet into a byte array
pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeI32(@intFromEnum(self.status), .big);
    return stream.getBuffer();
}

/// Deserialize the packet from a byte array
pub fn deserialize(stream: *BinaryStream) !Self {
    return .{
        .status = @enumFromInt(try stream.readI32(.big)),
    };
}

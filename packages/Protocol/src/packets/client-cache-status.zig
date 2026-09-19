const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 129;

cache_supported: bool = false,

pub fn deserialize(stream: *BinaryStream) !Self {
    return .{ .cache_supported = try stream.readBool() };
}

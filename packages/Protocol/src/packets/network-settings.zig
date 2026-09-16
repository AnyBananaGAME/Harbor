const CompressionMethod = @import("../enums/root.zig").CompressionMethod;
const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 143;

/// Minimum packet size before compression is used.
compressionThreshold: u16,

/// Compression algorithm used for packets.
compressionMethod: CompressionMethod,

/// Whether client-side throttling is enabled.
clientThrottle: bool,

/// Minimum threshold before client throttling starts.
clientThreshold: u8,

/// Multiplier used to scale client throttling.
clientScalar: f32,

/// Serialize the packet into a byte array
pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeU16(self.compressionThreshold, .little);
    try stream.writeU16(@intFromEnum(self.compressionMethod), .little);
    try stream.writeBool(self.clientThrottle);
    try stream.writeU8(self.clientThreshold);
    try stream.writeF32(self.clientScalar, .little);
    return stream.getBuffer();
}

/// Deserialize the packet from a byte array
pub fn deserialize(stream: *BinaryStream) !Self {
    return .{
        .compressionThreshold = try stream.readU16(.little),
        .compressionMethod = @enumFromInt(try stream.readU16(.little)),
        .clientThrottle = try stream.readBool(),
        .clientThreshold = try stream.readU8(),
        .clientScalar = try stream.readF32(.little),
    };
}

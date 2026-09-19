const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 340;

pub fn serialize(_: *Self, stream: *BinaryStream) ![]const u8 {
    return stream.getBuffer();
}

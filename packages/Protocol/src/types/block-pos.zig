const BinaryStream = @import("binarystream").BinaryStream;

pub const BlockPos = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarInt32(self.x);
        try stream.writeVarInt32(self.y);
        try stream.writeVarInt32(self.z);
    }
};

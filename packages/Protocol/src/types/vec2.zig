const BinaryStream = @import("binarystream").BinaryStream;

pub const Vec2 = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeF32(self.x, .little);
        try stream.writeF32(self.y, .little);
    }
};

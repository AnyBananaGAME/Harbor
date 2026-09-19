const BinaryStream = @import("binarystream").BinaryStream;

pub const ChunkPos = struct {
    x: i32 = 0,
    z: i32 = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarInt32(self.x);
        try stream.writeVarInt32(self.z);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        return .{
            .x = try stream.readVarInt32(),
            .z = try stream.readVarInt32(),
        };
    }
};

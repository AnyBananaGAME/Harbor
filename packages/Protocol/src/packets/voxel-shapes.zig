const BinaryStream = @import("binarystream").BinaryStream;

pub const VoxelShapesPacket = struct {
    pub const ID: u32 = 337;

    pub fn serialize(_: *const @This(), stream: *BinaryStream) ![]const u8 {
        try stream.writeVarUint32(0);
        try stream.writeVarUint32(0);
        try stream.writeU16(0, .little);
        return stream.getBuffer();
    }
};

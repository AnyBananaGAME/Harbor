const BinaryStream = @import("binarystream").BinaryStream;
const Nbt = @import("Nbt");

pub const JigsawStructureDataPacket = struct {
    pub const ID: u32 = 313;

    structure_data: Nbt.CompoundTag = .{ .value = .{} },

    pub fn serialize(self: *const @This(), stream: *BinaryStream) ![]const u8 {
        var tag = Nbt.Tag{ .Compound = self.structure_data };
        try tag.serialize(stream, .network);
        return stream.getBuffer();
    }
};

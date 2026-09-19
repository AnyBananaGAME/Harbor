const BinaryStream = @import("binarystream").BinaryStream;
const Nbt = @import("Nbt");

pub const ServerBlockProperty = struct {
    block_name: []const u8 = "",
    block_definition: Nbt.CompoundTag = .{ .value = .{} },

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.block_name);
        var tag = Nbt.Tag{ .Compound = self.block_definition };
        try tag.serialize(stream, .network);
    }
};

const BinaryStream = @import("binarystream").BinaryStream;

pub const AttributeModifier = struct {
    id: []const u8 = &.{},
    name: []const u8 = &.{},
    amount: f32 = 0,
    operation: i32 = 0,
    operand: i32 = 0,
    serializable: bool = false,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.id);
        try stream.writeVarString(self.name);
        try stream.writeF32(self.amount, .little);
        try stream.writeI32(self.operation, .little);
        try stream.writeI32(self.operand, .little);
        try stream.writeBool(self.serializable);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        return .{
            .id = try stream.readVarString(),
            .name = try stream.readVarString(),
            .amount = try stream.readF32(.little),
            .operation = try stream.readI32(.little),
            .operand = try stream.readI32(.little),
            .serializable = try stream.readBool(),
        };
    }
};

const BinaryStream = @import("binarystream").BinaryStream;

pub const ExperimentToggle = struct {
    name: []const u8 = "",
    enabled: bool = false,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.name);
        try stream.writeBool(self.enabled);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        return .{ .name = try stream.readVarString(), .enabled = try stream.readBool() };
    }
};

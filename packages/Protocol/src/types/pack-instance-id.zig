const BinaryStream = @import("binarystream").BinaryStream;

pub const PackInstanceId = struct {
    pack_id: []const u8 = "",
    version: []const u8 = "",
    subpack_name: []const u8 = "",

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.pack_id);
        try stream.writeVarString(self.version);
        try stream.writeVarString(self.subpack_name);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        return .{ .pack_id = try stream.readVarString(), .version = try stream.readVarString(), .subpack_name = try stream.readVarString() };
    }
};

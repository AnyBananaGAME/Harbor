const BinaryStream = @import("binarystream").BinaryStream;
pub const EduSharedUriResource = struct {
    button_name: []const u8 = "",
    link_uri: []const u8 = "",
    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.button_name);
        try stream.writeVarString(self.link_uri);
    }
    pub fn read(stream: *BinaryStream) !@This() {
        return .{ .button_name = try stream.readVarString(), .link_uri = try stream.readVarString() };
    }
};

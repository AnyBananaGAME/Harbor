const BinaryStream = @import("binarystream").BinaryStream;

pub const PackIdVersion = struct {
    pack_uuid: [16]u8 = [_]u8{0} ** 16,
    pack_version: []const u8 = "",

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeUuid(self.pack_uuid);
        try stream.writeVarString(self.pack_version);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        return .{ .pack_uuid = try stream.readUuid(), .pack_version = try stream.readVarString() };
    }
};

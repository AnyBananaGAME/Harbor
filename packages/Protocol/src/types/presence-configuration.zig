const BinaryStream = @import("binarystream").BinaryStream;

pub const PresenceConfiguration = struct {
    rich_presence_id: ?[]const u8 = null,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeBool(self.rich_presence_id != null);
        if (self.rich_presence_id) |value| try stream.writeVarString(value);
    }
};

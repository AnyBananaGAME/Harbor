const BinaryStream = @import("binarystream").BinaryStream;

pub const NetworkPermissions = struct {
    server_auth_sound_enabled: bool = false,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeBool(self.server_auth_sound_enabled);
    }
};

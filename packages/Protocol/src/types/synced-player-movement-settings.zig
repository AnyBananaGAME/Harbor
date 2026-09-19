const BinaryStream = @import("binarystream").BinaryStream;

pub const SyncedPlayerMovementSettings = struct {
    rewind_history_size: i32 = 0,
    server_authoritative_block_breaking: bool = false,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarInt32(self.rewind_history_size);
        try stream.writeBool(self.server_authoritative_block_breaking);
    }
};

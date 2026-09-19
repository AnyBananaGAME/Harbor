const BinaryStream = @import("binarystream").BinaryStream;

pub const ClientStoreEntryPointConfiguration = struct {
    store_id: []const u8 = "",
    store_name: []const u8 = "",

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.store_id);
        try stream.writeVarString(self.store_name);
    }
};

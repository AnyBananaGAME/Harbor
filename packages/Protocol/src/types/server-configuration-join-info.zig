const BinaryStream = @import("binarystream").BinaryStream;
const Gatherings = @import("gatherings-configuration-join-info.zig").GatheringsConfigurationJoinInfo;
const Store = @import("client-store-entry-point-configuration.zig").ClientStoreEntryPointConfiguration;
const Presence = @import("presence-configuration.zig").PresenceConfiguration;

pub const ServerConfigurationJoinInfo = struct {
    gathering: ?Gatherings = null,
    client_store_entry_point: ?Store = null,
    presence: ?Presence = null,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeBool(self.gathering != null);
        if (self.gathering) |*value| try value.write(stream);
        try stream.writeBool(self.client_store_entry_point != null);
        if (self.client_store_entry_point) |*value| try value.write(stream);
        try stream.writeBool(self.presence != null);
        if (self.presence) |*value| try value.write(stream);
    }
};

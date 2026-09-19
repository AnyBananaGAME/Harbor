const BinaryStream = @import("binarystream").BinaryStream;

pub const ServerTelemetryData = struct {
    server_id: []const u8 = "",
    scenario_id: []const u8 = "",
    world_id: []const u8 = "",
    owner_id: []const u8 = "",

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.server_id);
        try stream.writeVarString(self.scenario_id);
        try stream.writeVarString(self.world_id);
        try stream.writeVarString(self.owner_id);
    }
};

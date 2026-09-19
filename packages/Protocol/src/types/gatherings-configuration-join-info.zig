const BinaryStream = @import("binarystream").BinaryStream;
const Uuid = @import("uuid.zig").Uuid;

pub const GatheringsConfigurationJoinInfo = struct {
    experience_id: Uuid = .{},
    experience_name: []const u8 = "",
    world_id: ?Uuid = null,
    world_name: ?[]const u8 = null,
    creator_id: []const u8 = "",
    target_id: ?Uuid = null,
    scenario_id: ?[]const u8 = null,
    server_id: ?[]const u8 = null,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try self.experience_id.write(stream);
        try stream.writeVarString(self.experience_name);
        try stream.writeBool(self.world_id != null);
        if (self.world_id) |*value| try value.write(stream);
        try stream.writeBool(self.world_name != null);
        if (self.world_name) |value| try stream.writeVarString(value);
        try stream.writeVarString(self.creator_id);
        try stream.writeBool(self.target_id != null);
        if (self.target_id) |*value| try value.write(stream);
        try stream.writeBool(self.scenario_id != null);
        if (self.scenario_id) |value| try stream.writeVarString(value);
        try stream.writeBool(self.server_id != null);
        if (self.server_id) |value| try stream.writeVarString(value);
    }
};

const BinaryStream = @import("binarystream").BinaryStream;
const Nbt = @import("Nbt");
const Enums = @import("../enums/root.zig");
const Types = @import("../types/root.zig");

pub const StartGamePacket = struct {
    pub const ID: u32 = 11;

    entity_id: i64 = 0,
    runtime_id: u64 = 0,
    game_type: Enums.GameType = .Survival,
    position: Types.Vec3 = .{},
    rotation: Types.Vec2 = .{},
    settings: Types.LevelSettings = .{},
    level_id: []const u8 = "",
    level_name: []const u8 = "",
    template_content_identity: []const u8 = "",
    trial: bool = false,
    movement_settings: Types.SyncedPlayerMovementSettings = .{},
    level_current_time: u64 = 0,
    enchantment_seed: i32 = 0,
    block_properties: []const Types.ServerBlockProperty = &.{},
    multiplayer_correlation_id: []const u8 = "",
    enable_item_stack_net_manager: bool = false,
    server_version: []const u8 = "",
    player_property_data: Nbt.CompoundTag = .{ .value = .{} },
    server_block_type_registry_checksum: u64 = 0,
    world_template_id: Types.Uuid = .{},
    server_enabled_client_side_generation: bool = false,
    block_network_ids_are_hashes: bool = false,
    network_permissions: Types.NetworkPermissions = .{},
    server_configuration_join_info: ?Types.ServerConfigurationJoinInfo = null,
    server_telemetry_data: Types.ServerTelemetryData = .{},

    pub fn serialize(self: *const @This(), stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt64(self.entity_id);
        try stream.writeVarUint64(self.runtime_id);
        try stream.writeVarInt32(@intFromEnum(self.game_type));
        try self.position.write(stream);
        try self.rotation.write(stream);
        try self.settings.write(stream);
        try stream.writeVarString(self.level_id);
        try stream.writeVarString(self.level_name);
        try stream.writeVarString(self.template_content_identity);
        try stream.writeBool(self.trial);
        try self.movement_settings.write(stream);
        try stream.writeU64(self.level_current_time, .little);
        try stream.writeVarInt32(self.enchantment_seed);
        try stream.writeVarUint32(@intCast(self.block_properties.len));
        for (self.block_properties) |*property| try property.write(stream);
        try stream.writeVarString(self.multiplayer_correlation_id);
        try stream.writeBool(self.enable_item_stack_net_manager);
        try stream.writeVarString(self.server_version);
        var player_property_tag = Nbt.Tag{ .Compound = self.player_property_data };
        try player_property_tag.serialize(stream, .network);
        try stream.writeU64(self.server_block_type_registry_checksum, .little);
        try self.world_template_id.write(stream);
        try stream.writeBool(self.server_enabled_client_side_generation);
        try stream.writeBool(self.block_network_ids_are_hashes);
        try self.network_permissions.write(stream);
        try stream.writeBool(self.server_configuration_join_info != null);
        if (self.server_configuration_join_info) |*info| try info.write(stream);
        try self.server_telemetry_data.write(stream);

        return stream.getBuffer();
    }
};

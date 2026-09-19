const BinaryStream = @import("binarystream").BinaryStream;
const Enums = @import("../enums/root.zig");
const BlockPos = @import("block-pos.zig").BlockPos;
const SpawnSettings = @import("spawn-settings.zig").SpawnSettings;
const EduSharedUriResource = @import("edu-shared-uri-resource.zig").EduSharedUriResource;
const Experiments = @import("experiments.zig").Experiments;
const GameRulesChangedPacketData = @import("game-rules-changed-packet-data.zig").GameRulesChangedPacketData;

pub const LevelSettings = struct {
    seed: u64 = 0,
    spawn_settings: SpawnSettings = .{},
    generator_type: Enums.GeneratorType = .Overworld,
    game_type: Enums.GameType = .Survival,
    hardcore: bool = false,
    game_difficulty: Enums.Difficulty = .Normal,
    default_spawn_block_position: BlockPos = .{},
    achievements_disabled: bool = false,
    editor_world_type: Enums.EditorWorldType = .NonEditor,
    created_in_editor: bool = false,
    exported_from_editor: bool = false,
    day_cycle_stop_time: i32 = 0,
    education_edition_offer: Enums.EducationEditionOffer = .None,
    education_features_enabled: bool = false,
    education_product_id: []const u8 = "",
    rain_level: f32 = 0,
    lightning_level: f32 = 0,
    confirmed_platform_locked_content: bool = false,
    multiplayer_game_intent: bool = true,
    lan_broadcast_intent: bool = true,
    xbox_live_broadcast_setting: Enums.GamePublishSetting = .Public,
    platform_broadcast_setting: Enums.GamePublishSetting = .Public,
    commands_enabled: bool = true,
    texture_packs_required: bool = false,
    rules: GameRulesChangedPacketData = .{},
    experiments: Experiments = .{},
    bonus_chest_enabled: bool = false,
    start_with_map_enabled: bool = false,
    player_permissions: Enums.PlayerPermissionLevel = .Member,
    server_chunk_tick_range: i32 = 4,
    locked_behavior_pack: bool = false,
    locked_resource_pack: bool = false,
    from_locked_template: bool = false,
    use_msa_gamertags_only: bool = false,
    from_world_template: bool = false,
    world_template_option_locked: bool = false,
    only_spawn_v1_villagers: bool = false,
    persona_disabled: bool = false,
    custom_skins_disabled: bool = false,
    emote_chat_muted: bool = false,
    base_game_version: []const u8 = "1.26.50",
    limited_world_width: i32 = 0,
    limited_world_depth: i32 = 0,
    nether_type: bool = false,
    edu_shared_uri_resource: EduSharedUriResource = .{},
    override_force_experimental_gameplay: ?bool = null,
    chat_restriction_level: Enums.ChatRestrictionLevel = .None,
    disable_player_interactions: bool = false,
    server_editor_connection_policy: Enums.ServerEditorConnectionPolicy = .MatchWorldType,
    allow_anonymous_block_drops_in_editor_worlds: bool = false,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeU64(self.seed, .little);
        try self.spawn_settings.write(stream);
        try stream.writeVarInt32(@intFromEnum(self.generator_type));
        try stream.writeVarInt32(@intFromEnum(self.game_type));
        try stream.writeBool(self.hardcore);
        try stream.writeVarInt32(@intFromEnum(self.game_difficulty));
        try self.default_spawn_block_position.write(stream);
        try stream.writeBool(self.achievements_disabled);
        try stream.writeVarInt32(@intFromEnum(self.editor_world_type));
        try stream.writeBool(self.created_in_editor);
        try stream.writeBool(self.exported_from_editor);
        try stream.writeVarInt32(self.day_cycle_stop_time);
        try stream.writeVarUint32(@intFromEnum(self.education_edition_offer));
        try stream.writeBool(self.education_features_enabled);
        try stream.writeVarString(self.education_product_id);
        try stream.writeF32(self.rain_level, .little);
        try stream.writeF32(self.lightning_level, .little);
        try stream.writeBool(self.confirmed_platform_locked_content);
        try stream.writeBool(self.multiplayer_game_intent);
        try stream.writeBool(self.lan_broadcast_intent);
        try stream.writeVarInt32(@intFromEnum(self.xbox_live_broadcast_setting));
        try stream.writeVarInt32(@intFromEnum(self.platform_broadcast_setting));
        try stream.writeBool(self.commands_enabled);
        try stream.writeBool(self.texture_packs_required);
        try self.rules.write(stream);
        try self.experiments.write(stream);
        try stream.writeBool(self.bonus_chest_enabled);
        try stream.writeBool(self.start_with_map_enabled);
        try stream.writeU8(@intFromEnum(self.player_permissions));
        try stream.writeI32(self.server_chunk_tick_range, .little);
        try stream.writeBool(self.locked_behavior_pack);
        try stream.writeBool(self.locked_resource_pack);
        try stream.writeBool(self.from_locked_template);
        try stream.writeBool(self.use_msa_gamertags_only);
        try stream.writeBool(self.from_world_template);
        try stream.writeBool(self.world_template_option_locked);
        try stream.writeBool(self.only_spawn_v1_villagers);
        try stream.writeBool(self.persona_disabled);
        try stream.writeBool(self.custom_skins_disabled);
        try stream.writeBool(self.emote_chat_muted);
        try stream.writeVarString(self.base_game_version);
        try stream.writeI32(self.limited_world_width, .little);
        try stream.writeI32(self.limited_world_depth, .little);
        try stream.writeBool(self.nether_type);
        try self.edu_shared_uri_resource.write(stream);
        try stream.writeBool(self.override_force_experimental_gameplay != null);
        if (self.override_force_experimental_gameplay) |value| try stream.writeBool(value);
        try stream.writeU8(@intFromEnum(self.chat_restriction_level));
        try stream.writeBool(self.disable_player_interactions);
        try stream.writeVarInt32(@intFromEnum(self.server_editor_connection_policy));
        try stream.writeBool(self.allow_anonymous_block_drops_in_editor_worlds);
    }
};

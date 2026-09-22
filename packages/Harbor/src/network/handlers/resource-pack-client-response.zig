const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Protocol = @import("Protocol");
const NetherNet = @import("NetherNet");

const NetworkManager = @import("../manager.zig").NetworkManager;

const Logger = std.log.scoped(.ResourcePackClientResponse);

pub fn handle(
    network: *NetworkManager,
    stream: *BinaryStream,
    session: *NetherNet.Server.Session,
) !void {
    const response = try Protocol.Packets.ResourcePackClientResponsePacket.deserialize(
        stream,
        network.server.allocator,
    );
    defer if (response.downloading_packs.len != 0) {
        network.server.allocator.free(response.downloading_packs);
    };

    if (response.response == .ResourcePackStackFinished) {
        var jigsaw_buffer: [256]u8 = undefined;
        var jigsaw_stream = BinaryStream.init(&jigsaw_buffer, 0);
        var structure_data = Protocol.Nbt.CompoundTag.init(null);
        defer structure_data.deinit();
        try structure_data.set("processors", .{ .List = .{ .value = &.{} } });
        try structure_data.set("template_pools", .{ .List = .{ .value = &.{} } });
        try structure_data.set("jigsaws", .{ .List = .{ .value = &.{} } });
        try structure_data.set("structure_sets", .{ .List = .{ .value = &.{} } });

        var jigsaw = Protocol.Packets.JigsawStructureDataPacket{
            .structure_data = structure_data,
        };
        const jigsaw_payload = try jigsaw.serialize(&jigsaw_stream);
        try session.sendReliable(Protocol.Packets.JigsawStructureDataPacket.ID, jigsaw_payload);

        var voxel_buffer: [16]u8 = undefined;
        var voxel_stream = BinaryStream.init(&voxel_buffer, 0);
        var voxel = Protocol.Packets.VoxelShapesPacket{};
        const voxel_payload = try voxel.serialize(&voxel_stream);
        try session.sendReliable(Protocol.Packets.VoxelShapesPacket.ID, voxel_payload);

        var start_game_buffer: [128 * 1024]u8 = undefined;
        var start_game_stream = BinaryStream.init(&start_game_buffer, 0);
        var start_game = Protocol.Packets.StartGamePacket{
            // TODO: Entity.getNextRuntimeId or sum
            .entity_id = 1,
            // TODO: Entity.getNextRuntimeId or sum
            .runtime_id = 1,
            .enable_item_stack_net_manager = true,
            .block_network_ids_are_hashes = true,
            .level_id = "Harbor",
            .level_name = "Harbor",
            .multiplayer_correlation_id = "Harbor",
            .server_version = "1.26.50",
            .movement_settings = .{
                .rewind_history_size = 0,
                .server_authoritative_block_breaking = true,
            },
            // TODO: getSpawn point from world
            .position = .{ .x = 0, .y = 68, .z = 0 },
            .settings = .{
                .game_type = .Survival,
                .generator_type = .Overworld,
                .game_difficulty = .Normal,
                .base_game_version = "1.26.50",
                .nether_type = true,
                .multiplayer_game_intent = true,
                .lan_broadcast_intent = true,
                .commands_enabled = true,
            },
        };
        const start_game_payload = try start_game.serialize(&start_game_stream);
        try session.sendReliable(Protocol.Packets.StartGamePacket.ID, start_game_payload);

        var play_status_buffer: [16]u8 = undefined;
        var play_status_stream = BinaryStream.init(&play_status_buffer, 0);
        var play_status = Protocol.Packets.PlayStatusPacket{ .status = .PlayerSpawn };
        const play_status_payload = try play_status.serialize(&play_status_stream);
        try session.sendReliable(Protocol.Packets.PlayStatusPacket.ID, play_status_payload);

        return;
    }

    if (response.response != .DownloadingFinished) return;

    var payload: [256]u8 = undefined;
    var payload_stream = BinaryStream.init(&payload, 0);
    var stack = Protocol.Packets.ResourcePackStackPacket{
        .base_game_version = Protocol.CONSTANTS.MinecraftVersion,
    };
    const serialized = try stack.serialize(&payload_stream);

    try session.sendReliable(
        Protocol.Packets.ResourcePackStackPacket.ID,
        serialized,
    );
}

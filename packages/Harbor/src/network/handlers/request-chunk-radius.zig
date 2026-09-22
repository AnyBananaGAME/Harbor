const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Protocol = @import("Protocol");
const NetherNet = @import("NetherNet");

const NetworkManager = @import("../manager.zig").NetworkManager;
const Logger = std.log.scoped(.RequestChunkRadius);
const ChunkViewer = @import("../../player/chunk-viewer.zig").PlayerChunkView;

pub fn handle(
    network: *NetworkManager,
    stream: *BinaryStream,
    session: *NetherNet.Server.Session,
) !void {
    if (network.server.getPlayerBySession(session)) |player| {
        // request.chunk_radius can be a pretty high value,
        // e.g 76, and request.max_chunk_radius is mostly gonna be like 28
        const request = try Protocol.Packets.RequestChunkRadiusPacket.deserialize(stream);

        var payload: [8]u8 = undefined;
        var payload_stream = BinaryStream.init(&payload, 0);
        const world = network.server.getDefaultWorld() orelse return;
        const dimension = world.getDimension("overworld") orelse return;

        const radius: i32 = @intCast(ChunkViewer.negotiateChunkRadius(
            @intCast(request.chunk_radius),
            @intCast(request.max_chunk_radius),
            ChunkViewer.MAX_RADIUS,
        ));

        var response = Protocol.Packets.ChunkRadiusUpdatedPacket{ .chunk_radius = radius };
        const serialized = try response.serialize(&payload_stream);
        try session.sendReliable(Protocol.Packets.ChunkRadiusUpdatedPacket.ID, serialized);

        _ = try player.chunk_viewer.setChunkRadius(
            @intCast(request.chunk_radius),
            @intCast(request.max_chunk_radius),
            ChunkViewer.MAX_RADIUS,
            session,
            dimension,
            .{ .x = 0, .z = 0 },
        );
    }
}

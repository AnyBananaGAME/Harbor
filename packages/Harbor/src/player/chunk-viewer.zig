const std = @import("std");
const BinaryStream = @import("BinaryStream");
const NetherNet = @import("NetherNet");
const Protocol = @import("Protocol");
const ChunkPos = Protocol.Types.ChunkPos;
const Dimension = @import("../world/dimension.zig").Dimension;

const Logger = std.log.scoped(.PlayerChunkViewer);

pub const PlayerChunkView = struct {
    pub const MAX_RADIUS: usize = 32;
    pub const MAX_CHUNKS: usize =
        (MAX_RADIUS * 2 + 1) * (MAX_RADIUS * 2 + 1);

    loaded: [MAX_CHUNKS]ChunkPos = undefined,
    count: usize = 0,
    radius: usize = 0,

    /// Clears all loaded chunks and resets the chunk count.
    /// Does not reset the chunk radius.
    pub fn clear(self: *PlayerChunkView) void {
        self.count = 0;
    }

    /// Returns whether the chunk position is currently shown to the player
    pub fn contains(
        self: *const PlayerChunkView,
        position: ChunkPos,
    ) bool {
        for (self.loaded[0..self.count]) |loaded| {
            if (loaded.x == position.x and loaded.z == position.z) {
                return true;
            }
        }

        return false;
    }

    /// Adds a chunk position to the player's viewing list.
    /// PlayerChunkView already does this
    pub fn add(
        self: *PlayerChunkView,
        position: ChunkPos,
    ) !void {
        if (self.contains(position)) return;
        if (self.count == self.loaded.len) return error.ChunkViewFull;

        self.loaded[self.count] = position;
        self.count += 1;
    }

    /// Sets the chunk radius for the player chunk view.
    /// At the moment the limit is 32
    pub fn setChunkRadius(
        self: *PlayerChunkView,
        requested: usize,
        client_max: usize,
        server_max: usize,
        session: *NetherNet.Server.Session,
        dimension: *Dimension,
        center: ChunkPos,
    ) !i32 {
        // Since we set max radius to 32 up top we gotta follow it to not exceed it
        const c_radius: usize = @intCast(negotiateChunkRadius(
            requested,
            client_max,
            server_max,
        ));

        self.radius = c_radius;
        try self.sendRadius(session, dimension, center);
        return @intCast(c_radius);
    }

    /// Sends the chunk radius to the client.
    pub fn sendRadius(
        self: *PlayerChunkView,
        session: *NetherNet.Server.Session,
        dimension: *Dimension,
        center: ChunkPos,
    ) !void {
        const radius: i32 = @intCast(self.radius);

        var z = center.z - radius;
        while (z <= center.z + radius) : (z += 1) {
            var x = center.x - radius;
            while (x <= center.x + radius) : (x += 1) {
                try self.sendChunk(
                    session,
                    dimension,
                    .{ .x = x, .z = z },
                );
            }
        }

        var publisher_buffer: [64 * 1024]u8 = undefined;
        var publisher_stream = BinaryStream.BinaryStream.init(&publisher_buffer, 0);
        var publisher = Protocol.Packets.NetworkChunkPublisherUpdatePacket{
            .position = .{ .x = center.x * 16, .y = 69, .z = center.z * 16 },
            .radius = @intCast(self.radius * 16),
            .server_built_chunks = &.{},
        };
        const publisher_payload = try publisher.serialize(&publisher_stream);
        try session.sendReliable(
            Protocol.Packets.NetworkChunkPublisherUpdatePacket.ID,
            publisher_payload,
        );
    }

    /// Sends a chunk to the client.
    pub fn sendChunk(
        self: *PlayerChunkView,
        session: *NetherNet.Server.Session,
        dimension: *Dimension,
        position: ChunkPos,
    ) !void {
        if (self.contains(position)) return;

        const chunk = try dimension.getOrCreateChunk(position);

        var chunk_buffer: [2 * 1024 * 1024]u8 = undefined;
        var chunk_stream = BinaryStream.BinaryStream.init(&chunk_buffer, 0);
        try chunk.serialize(&chunk_stream, true);

        var packet_buffer: [2 * 1024 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.BinaryStream.init(&packet_buffer, 0);

        var packet = Protocol.Packets.LevelChunkPacket{
            .chunk_position = position,
            .dimension_id = @intFromEnum(dimension.typ),
            .sub_chunks_count = @intCast(chunk.getSubChunkSendCount()),
            .client_request_sub_chunk_limit = null,
            .cache_enabled = false,
            .cache_metadata_count = 0,
            .cache_metadata = &.{},
            .raw_payload = chunk_stream.bytes[0..chunk_stream.offset],
        };

        const payload = try packet.serialize(&packet_stream);

        try session.sendReliable(
            Protocol.Packets.LevelChunkPacket.ID,
            payload,
        );

        try self.add(position);
    }

    /// Negotiates the chunk radius for the player
    /// which is more optimal for the client and server
    pub fn negotiateChunkRadius(
        requested: usize,
        client_max: usize,
        server_max: usize,
    ) i32 {
        const max_bedrock_distance: i32 = MAX_RADIUS;
        const minimum_radius: i32 = 4;

        const client_limit = if (client_max > 0)
            @max(1, @min(client_max, max_bedrock_distance))
        else
            max_bedrock_distance;

        const maximum_server_radius = @max(
            minimum_radius,
            @min(server_max, max_bedrock_distance),
        );

        var maximum_client_radius: i32 = @intFromFloat(
            @floor(@as(f64, @floatFromInt(client_limit)) / @sqrt(2.0) - 1.0),
        );

        maximum_client_radius = @max(
            1,
            @min(maximum_client_radius, client_limit),
        );

        while (maximum_client_radius < client_limit and
            @trunc(@ceil(
                @as(f64, @floatFromInt(maximum_client_radius + 2)) * @sqrt(2.0),
            )) <= client_limit)
        {
            maximum_client_radius += 1;
        }

        const maximum = @min(maximum_server_radius, maximum_client_radius);
        return @max(minimum_radius, @min(requested, maximum));
    }
};

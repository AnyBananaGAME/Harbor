const std = @import("std");
const NetherNet = @import("NetherNet");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Protocol = @import("Protocol");
const Packets = Protocol.Packets;
const CompressionMethod = Protocol.Enums.CompressionMethod;

const Logger = std.log.scoped(.NetworkManager);

pub const NetworkManager = struct {
    server: *@import("../server.zig").Server,
    nethernet: NetherNet.Server.Server,

    pub fn init(
        server: *@import("../server.zig").Server,
    ) NetworkManager {
        return .{
            .server = server,
            .nethernet = NetherNet.Server.Server.init(
                server.io,
                server.allocator,
                "0.0.0.0",
                19132,
                onGamePacket,
                server,
            ),
        };
    }

    pub fn start(self: *NetworkManager) !void {
        try self.nethernet.start(
            "0.0.0.0",
            "../../.nethernet/files/certificate.pem",
            "../../.nethernet/files/private-key.pem",
            "../../.nethernet/files/identity-key.pem",
        );
    }

    pub fn decryptMessage(self: *NetworkManager, stream: *BinaryStream, session: *NetherNet.Server.Session, channel: c_int) !void {
        const compression: ?CompressionMethod = if (session.compression != null)
            @enumFromInt(try stream.readU8())
        else
            null;

        var decompressed_storage: [128 * 1024]u8 = undefined;
        if (compression == .Zlib) {
            const compressed = stream.bytes[stream.offset..];
            var compressed_reader = std.Io.Reader.fixed(compressed);
            var window: [std.compress.flate.max_window_len]u8 = undefined;
            var decompressor = std.compress.flate.Decompress.init(
                &compressed_reader,
                .raw,
                &window,
            );
            var output = std.Io.Writer.fixed(&decompressed_storage);
            _ = try decompressor.reader.streamRemaining(&output);
            stream.* = BinaryStream.init(decompressed_storage[0..output.end], 0);
        }

        while (!stream.eof()) {
            const length = try stream.readVarUint32();
            var packet_stream = BinaryStream.init(try stream.readBytes(length), 0);
            const id = try packet_stream.readVarUint32();
            switch (id) {
                Packets.RequestNetworkSettingsPacket.ID => {
                    const request = try Packets.RequestNetworkSettingsPacket.deserialize(&packet_stream);
                    Logger.info("received RequestNetworkSettingsPacket: protocol: {d}", .{request.protocol});
                    var settings = Packets.NetworkSettingsPacket{
                        .clientScalar = 0,
                        .clientThreshold = 0,
                        .clientThrottle = false,
                        .compressionMethod = .Zlib,
                        .compressionThreshold = 1,
                    };

                    var payload: [256]u8 = undefined;
                    var payload_stream = BinaryStream.init(&payload, 0);
                    _ = try settings.serialize(&payload_stream);
                    try session.sendUncompressed(channel, Packets.NetworkSettingsPacket.ID, payload_stream.getBuffer());
                    session.compression = @intFromEnum(CompressionMethod.Zlib);
                },
                Packets.LoginPacket.ID => try @import("./handlers/login.zig").handle(self, &packet_stream, session),
                Packets.ClientCacheStatusPacket.ID => {
                    const cache = try Packets.ClientCacheStatusPacket.deserialize(&packet_stream);
                    _ = cache; // autofix

                    var rpInfo = Protocol.Packets.ResourcePacksInfoPacket{
                        .force_disable_vibrant_visuals = false,
                        .has_addon_packs = false,
                        .has_scripts = false,
                        .resource_pack_required = false,
                        .resource_packs = &.{},
                        .world_template_id_and_version = .{
                            .pack_uuid = [_]u8{0} ** 16,
                            .pack_version = "",
                        },
                    };

                    var payload2: [256]u8 = undefined;
                    var stream2 = BinaryStream.init(&payload2, 0);
                    const rpInfoSerialized = rpInfo.serialize(&stream2) catch return;

                    session.sendReliable(
                        Protocol.Packets.ResourcePacksInfoPacket.ID,
                        rpInfoSerialized,
                    ) catch |err| {
                        Logger.err("Could not send ResourcePacksInfoPacket: {s}", .{@errorName(err)});
                        return;
                    };
                },
                Packets.ResourcePackClientResponsePacket.ID => {
                    try @import("./handlers/resource-pack-client-response.zig").handle(
                        self,
                        &packet_stream,
                        session,
                    );
                },
                Packets.PacketViolationWarningPacket.ID => try @import("./handlers/packet-violation-warning.zig").handle(self, &packet_stream),
                else => {
                    Logger.warn("Unknown packet ID {d}", .{id});
                    return;
                },
            }
        }
    }
};

fn onGamePacket(context: ?*anyopaque, session: *NetherNet.Server.Session, channel: c_int, data: []const u8) void {
    if (data.len < 1) return;
    const server: *@import("../server.zig").Server = @ptrCast(@alignCast(context.?));

    // info(NetworkManager): { 0, 6, 193, 1, 0, 0, 8, 144 }
    // 0 here is compression byte and 6 is the packet data length
    // Logger.info("{any}", .{data});

    var stream = BinaryStream.init(@constCast(data), 0);

    server.network.decryptMessage(&stream, session, channel) catch |err| {
        Logger.err("An error occured trying to decrypt a message: {any}", .{err});
        return;
    };
}

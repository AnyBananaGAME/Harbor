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

        Logger.info("Packet uses {any} compression", .{compression orelse .None});

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
                        .compressionThreshold = 0,
                    };

                    var payload: [256]u8 = undefined;
                    var payload_stream = BinaryStream.init(&payload, 0);
                    _ = try settings.serialize(&payload_stream);
                    try session.sendUncompressed(channel, Packets.NetworkSettingsPacket.ID, payload_stream.getBuffer());
                    session.compression = 0;
                },
                Packets.LoginPacket.ID => try @import("./handlers/login.zig").handle(self, &packet_stream, session),
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

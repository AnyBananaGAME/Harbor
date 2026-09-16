const std = @import("std");
const NetherNet = @import("NetherNet");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Packets = @import("Protocol").Packets;

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

    pub fn decryptMessage(_: *NetworkManager, stream: *BinaryStream) !void {
        const compression = try stream.readU8();
        Logger.info("Packet uses {d} compression", .{compression});

        while (!stream.eof()) {
            const length = try stream.readVarUint32();
            var packet_stream = BinaryStream.init(try stream.readBytes(length), 0);
            const id = try packet_stream.readVarUint32();
            switch (id) {
                Packets.RequestNetworkSettingsPacket.ID => {
                    const request = try Packets.RequestNetworkSettingsPacket.deserialize(&packet_stream);
                    Logger.info("received RequestNetworkSettingsPacket: protocol: {d}", .{request.protocol});
                },
                else => return error.UnknownPacketId,
            }
        }
    }
};

fn onGamePacket(context: ?*anyopaque, _: *NetherNet.Server.Session, _: c_int, data: []const u8) void {
    if (data.len < 1) return;
    const server: *@import("../server.zig").Server = @ptrCast(@alignCast(context.?));

    // info(NetworkManager): { 0, 6, 193, 1, 0, 0, 8, 144 }
    // 0 here is compression byte and 6 is the packet data length
    // Logger.info("{any}", .{data});

    var stream = BinaryStream.init(@constCast(data), 0);

    server.network.decryptMessage(&stream) catch |err| {
        Logger.err("An error occured trying to decrypt a message: {any}", .{err});
        return;
    };
}

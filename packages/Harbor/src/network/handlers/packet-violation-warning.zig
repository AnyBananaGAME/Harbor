const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Protocol = @import("Protocol");

const NetworkManager = @import("../manager.zig").NetworkManager;

const Logger = std.log.scoped(.PacketViolationWarning);

pub fn handle(
    _: *NetworkManager,
    stream: *BinaryStream,
) !void {
    const warning = try Protocol.Packets.PacketViolationWarningPacket.deserialize(stream);

    Logger.warn(
        "Packet violation: type: {any}, severity: {any}, packet_id: {d}, context: {s}",
        .{
            warning.violation_type,
            warning.violation_severity,
            warning.violation_packet_id,
            warning.violation_context,
        },
    );
}

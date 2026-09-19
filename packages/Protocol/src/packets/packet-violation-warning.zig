const BinaryStream = @import("binarystream").BinaryStream;
const Enums = @import("../enums/root.zig");

const Self = @This();

pub const ID: u32 = 156;

violation_type: Enums.PacketViolationType = .Unknown,
violation_severity: Enums.PacketViolationSeverity = .Unknown,
violation_packet_id: i32 = 0,
violation_context: []const u8 = "",

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeZigZag(@intFromEnum(self.violation_type));
    try stream.writeZigZag(@intFromEnum(self.violation_severity));
    try stream.writeZigZag(self.violation_packet_id);
    try stream.writeVarString(self.violation_context);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    return .{
        .violation_type = @enumFromInt(try stream.readZigZag()),
        .violation_severity = @enumFromInt(try stream.readZigZag()),
        .violation_packet_id = try stream.readZigZag(),
        .violation_context = try stream.readVarString(),
    };
}

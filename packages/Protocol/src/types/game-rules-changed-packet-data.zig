const BinaryStream = @import("binarystream").BinaryStream;
const GameRule = @import("game-rule.zig").GameRule;

pub const GameRulesChangedPacketData = struct {
    rules: []const GameRule = &.{},

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarUint32(@intCast(self.rules.len));
        for (self.rules) |*rule| try rule.write(stream);
    }
};

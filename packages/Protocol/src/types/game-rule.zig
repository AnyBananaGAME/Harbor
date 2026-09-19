const BinaryStream = @import("binarystream").BinaryStream;
const Enums = @import("../enums/root.zig");

pub const GameRule = struct {
    name: []const u8 = "",
    can_be_modified: bool = false,
    value_type: ?Enums.GameRuleValueType = null,
    bool_value: bool = false,
    int_value: i32 = 0,
    float_value: f32 = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeVarString(self.name);
        try stream.writeBool(self.can_be_modified);
        try stream.writeVarUint32(@intFromEnum(self.value_type orelse .None));

        switch (self.value_type orelse .None) {
            .None => {},
            .Bool => try stream.writeBool(self.bool_value),
            .Int => try stream.writeU32(@bitCast(self.int_value), .little),
            .Float => try stream.writeF32(self.float_value, .little),
        }
    }
};

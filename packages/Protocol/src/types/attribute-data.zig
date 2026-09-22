const BinaryStream = @import("binarystream").BinaryStream;
const AttributeModifier = @import("./attribute-modifier.zig").AttributeModifier;

pub const AttributeData = struct {
    pub const MaxModifiers = 64;

    minimum: f32 = 0,
    maximum: f32 = 0,
    current: f32 = 0,
    default_minimum: f32 = 0,
    default_maximum: f32 = 0,
    default_value: f32 = 0,
    name: []const u8 = &.{},
    modifiers: [MaxModifiers]AttributeModifier = undefined,
    modifiers_count: usize = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeF32(self.minimum, .little);
        try stream.writeF32(self.maximum, .little);
        try stream.writeF32(self.current, .little);
        try stream.writeF32(self.default_minimum, .little);
        try stream.writeF32(self.default_maximum, .little);
        try stream.writeF32(self.default_value, .little);
        try stream.writeVarString(self.name);
        try stream.writeVarUint32(@intCast(self.modifiers_count));
        for (self.modifiers[0..self.modifiers_count]) |*modifier| try modifier.write(stream);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        var self: @This() = .{};
        self.minimum = try stream.readF32(.little);
        self.maximum = try stream.readF32(.little);
        self.current = try stream.readF32(.little);
        self.default_minimum = try stream.readF32(.little);
        self.default_maximum = try stream.readF32(.little);
        self.default_value = try stream.readF32(.little);
        self.name = try stream.readVarString();
        self.modifiers_count = try stream.readVarUint32();
        if (self.modifiers_count > MaxModifiers) return error.TooManyAttributeModifiers;
        for (self.modifiers[0..self.modifiers_count]) |*modifier|
            modifier.* = try AttributeModifier.read(stream);
        return self;
    }
};

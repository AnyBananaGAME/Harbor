const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

pub const ID: u32 = 84;

resource_name: []const u8 = "",
chunk: i32 = 0,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarString(self.resource_name);
    try stream.writeI32(self.chunk, .little);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    return .{
        .resource_name = try stream.readVarString(),
        .chunk = try stream.readI32(.little),
    };
}

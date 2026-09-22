const BinaryStream = @import("binarystream").BinaryStream;
const AttributeData = @import("../types/attribute-data.zig").AttributeData;

pub const ID: u32 = 29;

const Self = @This();
pub const MaxAttributes = 64;

actor_runtime_id: u64,
attributes: [MaxAttributes]AttributeData = undefined,
attribute_count: usize = 0,
tick: u64,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarUint64(self.actor_runtime_id);
    try stream.writeVarUint32(@intCast(self.attribute_count));
    for (self.attributes[0..self.attribute_count]) |*attribute| try attribute.write(stream);
    try stream.writeVarUint64(self.tick);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    const actor_runtime_id = try stream.readVarUint64();
    const attributes_count = try stream.readVarUint32();
    if (attributes_count > MaxAttributes) return error.TooManyAttributes;
    var attributes: [MaxAttributes]AttributeData = undefined;
    for (attributes[0..attributes_count]) |*attribute|
        attribute.* = try AttributeData.read(stream);
    const tick = try stream.readVarUint64();

    return .{
        .actor_runtime_id = actor_runtime_id,
        .attributes = attributes,
        .attribute_count = attributes_count,
        .tick = tick,
    };
}

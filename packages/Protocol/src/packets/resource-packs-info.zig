const BinaryStream = @import("binarystream").BinaryStream;
const Types = @import("../types/root.zig");

const Self = @This();

pub const ID: u32 = 6;

resource_pack_required: bool = false,
has_addon_packs: bool = false,
has_scripts: bool = false,
force_disable_vibrant_visuals: bool = false,
world_template_id_and_version: Types.PackIdVersion = .{},
resource_packs: []const Types.PackInfoData = &.{},

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeBool(self.resource_pack_required);
    try stream.writeBool(self.has_addon_packs);
    try stream.writeBool(self.has_scripts);
    try stream.writeBool(self.force_disable_vibrant_visuals);
    try self.world_template_id_and_version.write(stream);
    try stream.writeVarUint32(@intCast(self.resource_packs.len));

    for (self.resource_packs) |*pack| {
        try pack.write(stream);
    }

    return stream.getBuffer();
}

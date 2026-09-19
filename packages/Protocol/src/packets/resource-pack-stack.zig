const BinaryStream = @import("binarystream").BinaryStream;
const Types = @import("../types/root.zig");

const Self = @This();

pub const ID: u32 = 7;

texture_pack_required: bool = false,
texture_pack_list: []const Types.PackInstanceId = &.{},
base_game_version: []const u8 = "",
experiments: Types.Experiments = .{},
include_editor_packs: bool = false,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeBool(self.texture_pack_required);
    try stream.writeVarUint32(@intCast(self.texture_pack_list.len));

    for (self.texture_pack_list) |*pack| {
        try pack.write(stream);
    }

    try stream.writeVarString(self.base_game_version);
    try self.experiments.write(stream);
    try stream.writeBool(self.include_editor_packs);
    return stream.getBuffer();
}

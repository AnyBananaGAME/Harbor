const BinaryStream = @import("binarystream").BinaryStream;
const Enums = @import("../enums/root.zig");

pub const SpawnSettings = struct {
    spawn_biome_type: Enums.SpawnBiomeType = .Default,
    user_defined_biome_name: []const u8 = "",
    dimension: i32 = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeI16(@intFromEnum(self.spawn_biome_type), .little);
        try stream.writeVarString(self.user_defined_biome_name);
        try stream.writeVarInt32(self.dimension);
    }
};

const BinaryStream = @import("binarystream").BinaryStream;
const PackIdVersion = @import("pack-id-version.zig").PackIdVersion;

pub const PackInfoData = struct {
    pack_id_version: PackIdVersion = .{},
    pack_size: u64 = 0,
    content_key: []const u8 = "",
    subpack_name: []const u8 = "",
    content_identity: []const u8 = "",
    has_scripts: bool = false,
    is_addon_pack: bool = false,
    is_ray_tracing_capable: bool = false,
    cdn_url: []const u8 = "",

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try self.pack_id_version.write(stream);
        try stream.writeU64(self.pack_size, .little);
        try stream.writeVarString(self.content_key);
        try stream.writeVarString(self.subpack_name);
        try stream.writeVarString(self.content_identity);
        try stream.writeBool(self.has_scripts);
        try stream.writeBool(self.is_addon_pack);
        try stream.writeBool(self.is_ray_tracing_capable);
        try stream.writeVarString(self.cdn_url);
    }

    pub fn read(stream: *BinaryStream) !@This() {
        return .{
            .pack_id_version = try PackIdVersion.read(stream),
            .pack_size = try stream.readU64(.little),
            .content_key = try stream.readVarString(),
            .subpack_name = try stream.readVarString(),
            .content_identity = try stream.readVarString(),
            .has_scripts = try stream.readBool(),
            .is_addon_pack = try stream.readBool(),
            .is_ray_tracing_capable = try stream.readBool(),
            .cdn_url = try stream.readVarString(),
        };
    }
};

const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const ShortTag = struct {
    pub const tag_type: TagType = .Short;

    value: i16,
    name: ?[]const u8 = null,

    pub fn init(value: i16, name: ?[]const u8) ShortTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *ShortTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !ShortTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Short)) return error.InvalidTagType;
        }

        return .{
            .name = try common.readName(stream, options),
            .value = try stream.readInt(i16, options.endian),
        };
    }

    pub fn serialize(self: ShortTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Short), .little);
        try common.writeName(stream, self.name, options);
        try stream.writeInt(i16, self.value, options.endian);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const FloatTag = struct {
    pub const tag_type: TagType = .Float;

    value: f32,
    name: ?[]const u8 = null,

    pub fn init(value: f32, name: ?[]const u8) FloatTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *FloatTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !FloatTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Float)) return error.InvalidTagType;
        }

        return .{
            .name = try common.readName(stream, options),
            .value = try stream.readInt(f32, options.endian),
        };
    }

    pub fn serialize(self: FloatTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Float), .little);
        try common.writeName(stream, self.name, options);
        try stream.writeInt(f32, self.value, options.endian);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

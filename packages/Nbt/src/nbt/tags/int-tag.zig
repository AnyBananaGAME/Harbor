const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const IntTag = struct {
    pub const tag_type: TagType = .Int;

    value: i32,
    name: ?[]const u8 = null,

    pub fn init(value: i32, name: ?[]const u8) IntTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *IntTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !IntTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Int)) return error.InvalidTagType;
        }

        return .{
            .name = try common.readName(stream, options),
            .value = try common.readInt32(stream, options),
        };
    }

    pub fn serialize(self: IntTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Int), .little);
        try common.writeName(stream, self.name, options);
        try common.writeInt32(stream, self.value, options);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

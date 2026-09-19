const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const StringTag = struct {
    pub const tag_type: TagType = .String;

    value: []const u8,
    name: ?[]const u8 = null,

    pub fn init(value: []const u8, name: ?[]const u8) StringTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *StringTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !StringTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.String)) return error.InvalidTagType;
        }

        const name = try common.readName(stream, options);
        const value_len = try common.readNameLength(stream, options);
        const value: []const u8 = if (value_len == 0) "" else try stream.readBytes(value_len);

        return .{ .name = name, .value = value };
    }

    pub fn serialize(self: StringTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.String), .little);
        try common.writeName(stream, self.name, options);
        try common.writeNameLength(stream, self.value.len, options);
        if (self.value.len != 0) try stream.writeBytes(self.value);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

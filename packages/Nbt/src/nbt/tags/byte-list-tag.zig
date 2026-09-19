const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const ByteListTag = struct {
    pub const tag_type: TagType = .ByteList;

    value: []const u8,
    name: ?[]const u8 = null,

    pub fn init(value: []const u8, name: ?[]const u8) ByteListTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *ByteListTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !ByteListTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.ByteList)) return error.InvalidTagType;
        }

        const name = try common.readName(stream, options);
        const len = try common.readLength32(stream, options);
        const value: []const u8 = if (len == 0) "" else try stream.readBytes(len);

        return .{ .name = name, .value = value };
    }

    pub fn serialize(self: ByteListTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.ByteList), .little);
        try common.writeName(stream, self.name, options);
        try common.writeLength32(stream, self.value.len, options);
        if (self.value.len != 0) try stream.writeBytes(self.value);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

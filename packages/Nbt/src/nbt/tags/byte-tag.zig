const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const ByteTag = struct {
    pub const tag_type: TagType = .Byte;

    value: i8,
    name: ?[]const u8 = null,

    pub fn init(value: i8, name: ?[]const u8) ByteTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *ByteTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !ByteTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Byte)) return error.InvalidTagType;
        }

        return .{
            .name = try common.readName(stream, options),
            .value = try stream.readInt(i8, options.endian),
        };
    }

    pub fn serialize(self: ByteTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Byte), .little);
        try common.writeName(stream, self.name, options);
        try stream.writeInt(i8, self.value, options.endian);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

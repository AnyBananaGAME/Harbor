const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const DoubleTag = struct {
    pub const tag_type: TagType = .Double;

    value: f64,
    name: ?[]const u8 = null,

    pub fn init(value: f64, name: ?[]const u8) DoubleTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *DoubleTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !DoubleTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Double)) return error.InvalidTagType;
        }

        return .{
            .name = try common.readName(stream, options),
            .value = try stream.readInt(f64, options.endian),
        };
    }

    pub fn serialize(self: DoubleTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Double), .little);
        try common.writeName(stream, self.name, options);
        try stream.writeInt(f64, self.value, options.endian);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

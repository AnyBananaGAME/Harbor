const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const LongTag = struct {
    pub const tag_type: TagType = .Long;

    value: i64,
    name: ?[]const u8 = null,

    pub fn init(value: i64, name: ?[]const u8) LongTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(_: *LongTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !LongTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Long)) return error.InvalidTagType;
        }

        return .{
            .name = try common.readName(stream, options),
            .value = try common.readInt64(stream, options),
        };
    }

    pub fn serialize(self: LongTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Long), .little);
        try common.writeName(stream, self.name, options);
        try common.writeInt64(stream, self.value, options);
    }

    pub const read = deserialize;
    pub const write = serialize;
};

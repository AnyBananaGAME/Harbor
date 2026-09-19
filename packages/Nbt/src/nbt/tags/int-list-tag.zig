const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

pub const IntListTag = struct {
    pub const tag_type: TagType = .IntList;

    value: []const i32,
    name: ?[]const u8 = null,

    pub fn init(value: []const i32, name: ?[]const u8) IntListTag {
        return .{ .value = value, .name = name };
    }

    pub fn deinit(self: *IntListTag) void {
        common.internal_allocator.free(self.value);
    }

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !IntListTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.IntList)) return error.InvalidTagType;
        }

        const name = try common.readName(stream, options);
        const len = try common.readLength32(stream, options);

        const value = try common.internal_allocator.alloc(i32, len);
        errdefer common.internal_allocator.free(value);

        for (value) |*v| {
            v.* = try common.readInt32(stream, options);
        }

        return .{ .name = name, .value = value };
    }

    pub fn serialize(self: IntListTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.IntList), .little);
        try common.writeName(stream, self.name, options);
        try common.writeLength32(stream, self.value.len, options);

        for (self.value) |v| {
            try common.writeInt32(stream, v, options);
        }
    }

    pub const read = deserialize;
    pub const write = serialize;
};

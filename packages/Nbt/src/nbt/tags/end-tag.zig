const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;

pub const EndTag = struct {
    pub const tag_type: TagType = .End;

    pub fn init() EndTag {
        return .{};
    }

    pub fn deinit(_: *EndTag) void {}

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !EndTag {
        if (options.tag_type) {
            const read_type = try stream.readInt(u8, .little);
            if (read_type != @intFromEnum(TagType.End)) return error.InvalidTagType;
        }

        return .{};
    }

    pub fn serialize(_: EndTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) {
            try stream.writeInt(u8, @intFromEnum(TagType.End), .little);
        }
    }

    pub const read = deserialize;
    pub const write = serialize;
};

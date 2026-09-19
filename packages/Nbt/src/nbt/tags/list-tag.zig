const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const Tag = @import("./tag.zig").Tag;
const common = @import("./common.zig");

pub const ListTag = struct {
    pub const tag_type: TagType = .List;

    value: []Tag,
    name: ?[]const u8 = null,

    pub fn init(value: []Tag, name: ?[]const u8) ListTag {
        return .{ .value = value, .name = name };
    }

    pub fn initEmpty(name: ?[]const u8) !ListTag {
        return .{
            .value = try common.internal_allocator.alloc(Tag, 0),
            .name = name,
        };
    }

    pub fn deinit(self: *ListTag) void {
        for (self.value) |*tag| tag.deinit();
        common.internal_allocator.free(self.value);
    }

    pub fn getElementType(self: *const ListTag) TagType {
        if (self.value.len == 0) return .Byte;
        return self.value[0].getType();
    }

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) anyerror!ListTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.List)) return error.InvalidTagType;
        }

        const name = try common.readName(stream, options);

        const raw_element_type = try common.readTagTypeByte(stream);
        const max_tag_value = @intFromEnum(TagType.LongList);
        if (raw_element_type > max_tag_value) return error.InvalidTagType;
        const element_type: TagType = @enumFromInt(raw_element_type);

        const len = try common.readLength32(stream, options);
        const value = try common.internal_allocator.alloc(Tag, len);
        errdefer common.internal_allocator.free(value);

        var initialized: usize = 0;
        errdefer {
            var i: usize = 0;
            while (i < initialized) : (i += 1) value[i].deinit();
        }

        const element_options: ReadWriteOptions = .{
            .name = false,
            .tag_type = false,
            .varint = options.varint,
            .endian = options.endian,
        };

        while (initialized < len) : (initialized += 1) {
            value[initialized] = try Tag.deserializeWithType(stream, element_type, element_options);
        }

        return .{ .name = name, .value = value };
    }

    pub fn serialize(self: ListTag, stream: *BinaryStream, options: ReadWriteOptions) anyerror!void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.List), .little);
        try common.writeName(stream, self.name, options);

        const element_type = self.getElementType();
        try stream.writeInt(u8, @intFromEnum(element_type), .little);
        try common.writeLength32(stream, self.value.len, options);

        const element_options: ReadWriteOptions = .{
            .name = false,
            .tag_type = false,
            .varint = options.varint,
            .endian = options.endian,
        };

        for (self.value) |tag| {
            try tag.serialize(stream, element_options);
        }
    }

    pub const read = deserialize;
    pub const write = serialize;
};

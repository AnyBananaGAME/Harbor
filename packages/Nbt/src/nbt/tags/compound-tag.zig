const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const Tag = @import("./tag.zig").Tag;
const common = @import("./common.zig");

pub const CompoundTag = struct {
    pub const tag_type: TagType = .Compound;

    value: std.StringHashMapUnmanaged(Tag),
    name: ?[]const u8 = null,

    pub fn init(name: ?[]const u8) CompoundTag {
        return .{
            .value = .{},
            .name = name,
        };
    }

    pub fn deinit(self: *CompoundTag) void {
        var it = self.value.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.value.deinit(common.internal_allocator);
    }

    pub fn get(self: *const CompoundTag, name: []const u8) ?Tag {
        return self.value.get(name);
    }

    pub fn set(self: *CompoundTag, name: []const u8, tag: Tag) !void {
        var mutable_tag = tag;
        mutable_tag.setName(name);
        try self.value.put(common.internal_allocator, name, mutable_tag);
    }

    pub fn add(self: *CompoundTag, tag: Tag) !void {
        const tag_name = tag.getName() orelse "";
        try self.value.put(common.internal_allocator, tag_name, tag);
    }

    pub fn push(self: *CompoundTag, tags: []const Tag) !void {
        for (tags) |tag| {
            try self.add(tag);
        }
    }

    pub fn contains(self: *const CompoundTag, name: []const u8) bool {
        return self.value.contains(name);
    }

    pub fn count(self: *const CompoundTag) usize {
        return self.value.count();
    }

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) anyerror!CompoundTag {
        if (options.tag_type) {
            const read_type = try common.readTagTypeByte(stream);
            if (read_type != @intFromEnum(TagType.Compound)) return error.InvalidTagType;
        }

        const name = try common.readName(stream, options);

        var value: std.StringHashMapUnmanaged(Tag) = .{};
        errdefer {
            var it = value.iterator();
            while (it.next()) |entry| entry.value_ptr.deinit();
            value.deinit(common.internal_allocator);
        }

        const child_options: ReadWriteOptions = .{
            .name = true,
            .tag_type = false,
            .varint = options.varint,
            .endian = options.endian,
        };

        while (true) {
            const raw = try common.readTagTypeByte(stream);
            const max_tag_value = @intFromEnum(TagType.LongList);
            if (raw > max_tag_value) return error.InvalidTagType;
            const child_type: TagType = @enumFromInt(raw);
            if (child_type == .End) break;

            const child = try Tag.deserializeWithType(stream, child_type, child_options);
            const child_name = child.getName() orelse "";
            try value.put(common.internal_allocator, child_name, child);
        }

        return .{
            .value = value,
            .name = name,
        };
    }

    pub fn serialize(self: CompoundTag, stream: *BinaryStream, options: ReadWriteOptions) !void {
        if (options.tag_type) try stream.writeInt(u8, @intFromEnum(TagType.Compound), .little);
        try common.writeName(stream, self.name, options);

        const child_options: ReadWriteOptions = .{
            .name = true,
            .tag_type = true,
            .varint = options.varint,
            .endian = options.endian,
        };

        var it = self.value.iterator();
        while (it.next()) |entry| {
            try entry.value_ptr.serialize(stream, child_options);
        }

        try stream.writeInt(u8, @intFromEnum(TagType.End), .little);
    }

    pub fn clone(self: *const CompoundTag) !CompoundTag {
        const cloned = try Tag.clone(&.{ .Compound = self.* });
        return cloned.Compound;
    }

    pub const read = deserialize;
    pub const write = serialize;
};

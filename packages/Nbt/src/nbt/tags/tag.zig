const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;
const TagType = @import("../tag-type.zig").TagType;
const common = @import("./common.zig");

const EndTag = @import("./end-tag.zig").EndTag;
const ByteTag = @import("./byte-tag.zig").ByteTag;
const ShortTag = @import("./short-tag.zig").ShortTag;
const IntTag = @import("./int-tag.zig").IntTag;
const LongTag = @import("./long-tag.zig").LongTag;
const FloatTag = @import("./float-tag.zig").FloatTag;
const DoubleTag = @import("./double-tag.zig").DoubleTag;
const StringTag = @import("./string-tag.zig").StringTag;
const ByteListTag = @import("./byte-list-tag.zig").ByteListTag;
const ListTag = @import("./list-tag.zig").ListTag;
const CompoundTag = @import("./compound-tag.zig").CompoundTag;
const IntListTag = @import("./int-list-tag.zig").IntListTag;
const LongListTag = @import("./long-list-tag.zig").LongListTag;

pub const Tag = union(TagType) {
    End: EndTag,
    Byte: ByteTag,
    Short: ShortTag,
    Int: IntTag,
    Long: LongTag,
    Float: FloatTag,
    Double: DoubleTag,
    ByteList: ByteListTag,
    String: StringTag,
    List: ListTag,
    Compound: CompoundTag,
    IntList: IntListTag,
    LongList: LongListTag,

    pub fn deinit(self: *Tag) void {
        switch (self.*) {
            .End => |*tag| tag.deinit(),
            .Byte => |*tag| tag.deinit(),
            .Short => |*tag| tag.deinit(),
            .Int => |*tag| tag.deinit(),
            .Long => |*tag| tag.deinit(),
            .Float => |*tag| tag.deinit(),
            .Double => |*tag| tag.deinit(),
            .ByteList => |*tag| tag.deinit(),
            .String => |*tag| tag.deinit(),
            .List => |*tag| tag.deinit(),
            .Compound => |*tag| tag.deinit(),
            .IntList => |*tag| tag.deinit(),
            .LongList => |*tag| tag.deinit(),
        }
    }

    pub fn getName(self: *const Tag) ?[]const u8 {
        return switch (self.*) {
            .End => null,
            .Byte => |tag| tag.name,
            .Short => |tag| tag.name,
            .Int => |tag| tag.name,
            .Long => |tag| tag.name,
            .Float => |tag| tag.name,
            .Double => |tag| tag.name,
            .ByteList => |tag| tag.name,
            .String => |tag| tag.name,
            .List => |tag| tag.name,
            .Compound => |tag| tag.name,
            .IntList => |tag| tag.name,
            .LongList => |tag| tag.name,
        };
    }

    pub fn getType(self: *const Tag) TagType {
        return @as(TagType, self.*);
    }

    pub fn setName(self: *Tag, name: ?[]const u8) void {
        switch (self.*) {
            .End => {},
            .Byte => |*tag| tag.name = name,
            .Short => |*tag| tag.name = name,
            .Int => |*tag| tag.name = name,
            .Long => |*tag| tag.name = name,
            .Float => |*tag| tag.name = name,
            .Double => |*tag| tag.name = name,
            .ByteList => |*tag| tag.name = name,
            .String => |*tag| tag.name = name,
            .List => |*tag| tag.name = name,
            .Compound => |*tag| tag.name = name,
            .IntList => |*tag| tag.name = name,
            .LongList => |*tag| tag.name = name,
        }
    }

    pub fn deserialize(stream: *BinaryStream, options: ReadWriteOptions) !Tag {
        const raw_type = try stream.readInt(u8, .little);
        const tag_type: TagType = @enumFromInt(raw_type);

        const read_options: ReadWriteOptions = .{
            .name = options.name,
            .tag_type = false,
            .varint = options.varint,
            .endian = options.endian,
        };

        return deserializeWithType(stream, tag_type, read_options);
    }

    pub fn deserializeWithType(stream: *BinaryStream, tag_type: TagType, options: ReadWriteOptions) !Tag {
        return switch (tag_type) {
            .End => .{ .End = try EndTag.deserialize(stream, options) },
            .Byte => .{ .Byte = try ByteTag.deserialize(stream, options) },
            .Short => .{ .Short = try ShortTag.deserialize(stream, options) },
            .Int => .{ .Int = try IntTag.deserialize(stream, options) },
            .Long => .{ .Long = try LongTag.deserialize(stream, options) },
            .Float => .{ .Float = try FloatTag.deserialize(stream, options) },
            .Double => .{ .Double = try DoubleTag.deserialize(stream, options) },
            .ByteList => .{ .ByteList = try ByteListTag.deserialize(stream, options) },
            .String => .{ .String = try StringTag.deserialize(stream, options) },
            .List => .{ .List = try ListTag.deserialize(stream, options) },
            .Compound => .{ .Compound = try CompoundTag.deserialize(stream, options) },
            .IntList => .{ .IntList = try IntListTag.deserialize(stream, options) },
            .LongList => .{ .LongList = try LongListTag.deserialize(stream, options) },
            _ => error.UnknownTagType,
        };
    }

    pub fn serialize(self: *const Tag, stream: *BinaryStream, options: ReadWriteOptions) anyerror!void {
        switch (self.*) {
            .End => |tag| try tag.serialize(stream, options),
            .Byte => |tag| try tag.serialize(stream, options),
            .Short => |tag| try tag.serialize(stream, options),
            .Int => |tag| try tag.serialize(stream, options),
            .Long => |tag| try tag.serialize(stream, options),
            .Float => |tag| try tag.serialize(stream, options),
            .Double => |tag| try tag.serialize(stream, options),
            .ByteList => |tag| try tag.serialize(stream, options),
            .String => |tag| try tag.serialize(stream, options),
            .List => |tag| try tag.serialize(stream, options),
            .Compound => |tag| try tag.serialize(stream, options),
            .IntList => |tag| try tag.serialize(stream, options),
            .LongList => |tag| try tag.serialize(stream, options),
        }
    }

    /// Clones the tag recursively
    pub fn clone(self: *const Tag) anyerror!Tag {
        return switch (self.*) {
            .End => .{ .End = .{} },
            .Byte => |t| .{ .Byte = .{ .value = t.value, .name = try cloneName(t.name) } },
            .Short => |t| .{ .Short = .{ .value = t.value, .name = try cloneName(t.name) } },
            .Int => |t| .{ .Int = .{ .value = t.value, .name = try cloneName(t.name) } },
            .Long => |t| .{ .Long = .{ .value = t.value, .name = try cloneName(t.name) } },
            .Float => |t| .{ .Float = .{ .value = t.value, .name = try cloneName(t.name) } },
            .Double => |t| .{ .Double = .{ .value = t.value, .name = try cloneName(t.name) } },
            .ByteList => |t| .{ .ByteList = .{
                .value = try common.internal_allocator.dupe(u8, t.value),
                .name = try cloneName(t.name),
            } },
            .String => |t| .{ .String = .{
                .value = try common.internal_allocator.dupe(u8, t.value),
                .name = try cloneName(t.name),
            } },
            .List => |t| blk: {
                const items = try common.internal_allocator.alloc(Tag, t.value.len);
                var initialized: usize = 0;
                errdefer {
                    var i: usize = 0;
                    while (i < initialized) : (i += 1) items[i].deinit();
                    common.internal_allocator.free(items);
                }
                while (initialized < t.value.len) : (initialized += 1) {
                    items[initialized] = try t.value[initialized].clone();
                }
                break :blk .{ .List = .{ .value = items, .name = try cloneName(t.name) } };
            },
            .Compound => |t| blk: {
                var new_map: std.StringHashMapUnmanaged(Tag) = .{};
                errdefer {
                    var it = new_map.iterator();
                    while (it.next()) |entry| entry.value_ptr.deinit();
                    new_map.deinit(common.internal_allocator);
                }

                var it = t.value.iterator();
                while (it.next()) |entry| {
                    var cloned_child = try entry.value_ptr.clone();
                    const key = cloned_child.getName() orelse "";
                    try new_map.put(common.internal_allocator, key, cloned_child);
                }

                break :blk .{ .Compound = .{ .value = new_map, .name = try cloneName(t.name) } };
            },
            .IntList => |t| .{ .IntList = .{
                .value = try common.internal_allocator.dupe(i32, t.value),
                .name = try cloneName(t.name),
            } },
            .LongList => |t| .{ .LongList = .{
                .value = try common.internal_allocator.dupe(i64, t.value),
                .name = try cloneName(t.name),
            } },
        };
    }

    fn cloneName(name: ?[]const u8) !?[]const u8 {
        return if (name) |n| try common.internal_allocator.dupe(u8, n) else null;
    }

    pub const read = deserialize;
    pub const readWithType = deserializeWithType;
    pub const write = serialize;
};

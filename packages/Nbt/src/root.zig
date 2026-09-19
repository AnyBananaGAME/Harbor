const std = @import("std");

pub const ReadWriteOptions = @import("nbt/read-write-options.zig").ReadWriteOptions;
pub const TagType = @import("nbt/tag-type.zig").TagType;
pub const Tag = @import("nbt/tags/tag.zig").Tag;
pub const EndTag = @import("nbt/tags/end-tag.zig").EndTag;
pub const ByteTag = @import("nbt/tags/byte-tag.zig").ByteTag;
pub const ShortTag = @import("nbt/tags/short-tag.zig").ShortTag;
pub const IntTag = @import("nbt/tags/int-tag.zig").IntTag;
pub const LongTag = @import("nbt/tags/long-tag.zig").LongTag;
pub const FloatTag = @import("nbt/tags/float-tag.zig").FloatTag;
pub const DoubleTag = @import("nbt/tags/double-tag.zig").DoubleTag;
pub const StringTag = @import("nbt/tags/string-tag.zig").StringTag;
pub const ByteListTag = @import("nbt/tags/byte-list-tag.zig").ByteListTag;
pub const ListTag = @import("nbt/tags/list-tag.zig").ListTag;
pub const CompoundTag = @import("nbt/tags/compound-tag.zig").CompoundTag;
pub const IntListTag = @import("nbt/tags/int-list-tag.zig").IntListTag;
pub const LongListTag = @import("nbt/tags/long-list-tag.zig").LongListTag;

test "integer tags support both byte orders" {
    const BinaryStream = @import("binarystream").BinaryStream;

    var bytes: [16]u8 = undefined;
    var stream = BinaryStream.init(&bytes, 0);
    const value = IntTag.init(0x10203040, "value");

    try value.serialize(&stream, .big_endian);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 3, 0, 5, 'v', 'a', 'l', 'u', 'e', 0x10, 0x20, 0x30, 0x40 }, stream.getBuffer());

    stream.offset = 0;
    const decoded = try IntTag.deserialize(&stream, .big_endian);
    try std.testing.expectEqual(@as(i32, 0x10203040), decoded.value);
}

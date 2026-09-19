const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ReadWriteOptions = @import("../read-write-options.zig").ReadWriteOptions;

pub const internal_allocator = std.heap.page_allocator;

pub inline fn readTagTypeByte(stream: *BinaryStream) !u8 {
    return stream.readInt(u8, .little);
}

pub fn readName(stream: *BinaryStream, options: ReadWriteOptions) !?[]const u8 {
    if (!options.name) return null;

    const len = try readNameLength(stream, options);
    if (len == 0) return null;

    const name = try stream.readBytes(len);
    return name;
}

pub fn writeName(stream: *BinaryStream, name: ?[]const u8, options: ReadWriteOptions) !void {
    if (!options.name) return;

    const n = name orelse "";
    try writeNameLength(stream, n.len, options);
    if (n.len != 0) {
        try stream.writeBytes(n);
    }
}

pub fn readNameLength(stream: *BinaryStream, options: ReadWriteOptions) !usize {
    if (options.varint) {
        const raw = try stream.readVarInt();
        if (raw > std.math.maxInt(u16)) return error.LengthTooLarge;
        return @intCast(raw);
    }

    return @intCast(try stream.readInt(u16, options.endian));
}

pub fn writeNameLength(stream: *BinaryStream, len: usize, options: ReadWriteOptions) !void {
    if (len > std.math.maxInt(u16)) return error.LengthTooLarge;

    if (options.varint) {
        try stream.writeVarInt(@intCast(len));
        return;
    }

    try stream.writeInt(u16, @intCast(len), options.endian);
}

pub fn readLength32(stream: *BinaryStream, options: ReadWriteOptions) !usize {
    const signed: i32 = if (options.varint)
        try stream.readZigZag()
    else
        try stream.readInt(i32, options.endian);

    if (signed < 0) return error.NegativeLength;
    return @intCast(signed);
}

pub fn writeLength32(stream: *BinaryStream, len: usize, options: ReadWriteOptions) !void {
    if (len > std.math.maxInt(i32)) return error.LengthTooLarge;
    const signed: i32 = @intCast(len);

    if (options.varint) {
        try stream.writeZigZag(signed);
        return;
    }

    try stream.writeInt(i32, signed, options.endian);
}

pub fn readInt32(stream: *BinaryStream, options: ReadWriteOptions) !i32 {
    if (options.varint) return stream.readZigZag();
    return stream.readInt(i32, options.endian);
}

pub fn writeInt32(stream: *BinaryStream, value: i32, options: ReadWriteOptions) !void {
    if (options.varint) {
        try stream.writeZigZag(value);
        return;
    }

    try stream.writeInt(i32, value, options.endian);
}

pub fn readInt64(stream: *BinaryStream, options: ReadWriteOptions) !i64 {
    if (!options.varint) return stream.readInt(i64, options.endian);

    const unsigned = try readVarUInt64(stream);
    const decoded: u64 = (unsigned >> 1) ^ (0 -% (unsigned & 1));
    return @bitCast(decoded);
}

pub fn writeInt64(stream: *BinaryStream, value: i64, options: ReadWriteOptions) !void {
    if (!options.varint) {
        try stream.writeInt(i64, value, options.endian);
        return;
    }

    const encoded: u64 = @bitCast((value << 1) ^ (value >> 63));
    try writeVarUInt64(stream, encoded);
}

fn readVarUInt64(stream: *BinaryStream) !u64 {
    var value: u64 = 0;
    var shift: u8 = 0;

    while (true) {
        const byte = try stream.readInt(u8, .little);
        value |= @as(u64, byte & 0x7f) << @as(u6, @intCast(shift));

        if ((byte & 0x80) == 0) return value;

        shift += 7;
        if (shift >= 64) return error.VarIntTooBig;
    }
}

fn writeVarUInt64(stream: *BinaryStream, value: u64) !void {
    var remaining = value;

    while (true) {
        var byte: u8 = @truncate(remaining & 0x7f);
        remaining >>= 7;

        if (remaining != 0) byte |= 0x80;
        try stream.writeInt(u8, byte, .little);

        if (remaining == 0) return;
    }
}

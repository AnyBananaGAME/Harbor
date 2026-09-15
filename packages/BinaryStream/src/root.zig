// NOTE: I am not sure about the correctness of std.debug.assert

const std = @import("std");
pub const Endian = std.builtin.Endian;

pub const BinaryStreamError = error{
    EndOfStream,
};

pub const BinaryStream = struct {
    /// The bytes of the stream.
    bytes: []u8,

    /// The current offset in the stream.
    offset: usize = 0,

    /// Self reference.
    const Self = @This();

    /// Initialize a new BinaryStream.
    ///
    /// Requires a byte slice as a parameter.
    pub fn init(bytes: []u8, offset: usize) BinaryStream {
        return BinaryStream{
            .bytes = bytes,
            .offset = offset,
        };
    }

    pub fn eof(self: *const Self) bool {
        return self.offset >= self.bytes.len;
    }

    /// Write a byte to the stream.
    /// Automatically increments the offset.
    pub inline fn writeByte(self: *BinaryStream, byte: u8) !void {
        self.bytes[self.offset] = byte;
        self.offset += 1;
    }

    pub fn readBool(self: *Self) !bool {
        return try self.readU8() != 0;
    }

    pub fn writeBool(self: *Self, value: bool) !void {
        return self.writeByte(@intFromBool(value));
    }

    pub inline fn readInt(self: *Self, comptime T: type, endian: Endian) !T {
        if (T == bool) return try self.readBool();
        if (T == u8) return try self.readU8();
        if (T == i8) return try self.readI8();
        if (T == u16) return try self.readU16(endian);
        if (T == i16) return try self.readI16(endian);
        if (T == u24) return try self.readU24(endian);
        if (T == u32) return try self.readU32(endian);
        if (T == i32) return try self.readI32(endian);
        if (T == u64) return try self.readU64(endian);
        if (T == i64) return try self.readI64(endian);
        if (T == f32) return try self.readF32(endian);
        if (T == f64) return try self.readF64(endian);
        @compileError("unsupported readInt type");
    }

    pub inline fn writeInt(self: *Self, comptime T: type, value: T, endian: Endian) !void {
        if (T == bool) return self.writeBool(value);
        if (T == u8) return self.writeU8(value);
        if (T == i8) return self.writeI8(value);
        if (T == u16) return self.writeU16(value, endian);
        if (T == i16) return self.writeI16(value, endian);
        if (T == u24) return self.writeU24(value, endian);
        if (T == i24) return self.writeI24(value, endian);
        if (T == u32) return self.writeU32(value, endian);
        if (T == i32) return self.writeI32(value, endian);
        if (T == u64) return self.writeU64(value, endian);
        if (T == i64) return self.writeI64(value, endian);
        if (T == f32) return self.writeF32(value, endian);
        if (T == f64) return self.writeF64(value, endian);
        @compileError("unsupported writeInt type");
    }

    pub inline fn readVarInt(self: *Self) !u32 {
        return self.readVarUint32();
    }

    pub inline fn writeVarInt(self: *Self, value: u32) !void {
        try self.writeVarUint32(value);
    }

    pub inline fn readZigZag(self: *Self) !i32 {
        const value = try self.readVarUint32();
        var decoded: i32 = @intCast(value >> 1);
        if ((value & 1) != 0) decoded = ~decoded;
        return decoded;
    }

    pub inline fn writeZigZag(self: *Self, value: i32) !void {
        try self.writeVarInt32(value);
    }

    /// Writes a Uint32 VarInt to the stream.
    pub inline fn writeVarUint32(self: *Self, value: u32) !void {
        var u_value = value;

        while (u_value >= 0x80) {
            try self.writeByte(@as(u8, @truncate(u_value & 0x7F)) | 0x80);
            u_value >>= 7;
        }
        try self.writeByte(@as(u8, @truncate(u_value)));
    }

    /// Writes a Int32 VarInt to the stream. (Int Varints are ZigZagged)
    pub inline fn writeVarInt32(self: *Self, value: i32) !void {
        const zigzagged = @as(u32, @bitCast((value << 1) ^ (value >> 31)));
        try self.writeVarUint32(zigzagged);
    }

    /// Writes a Uint64 VarInt to the stream.
    pub inline fn writeVarUint64(self: *Self, value: u64) !void {
        var u_value = value;
        while (u_value >= 0x80) {
            try self.writeByte(@as(u8, @truncate(u_value & 0x7F)) | 0x80);
            u_value >>= 7;
        }
        try self.writeByte(@as(u8, @truncate(u_value)));
    }

    /// Writes a Int64 VarInt to the stream. (Int Varints are ZigZagged)
    pub inline fn writeVarInt64(self: *Self, value: i64) !void {
        const zigzagged = @as(u64, @bitCast((value << 1) ^ (value >> 63)));
        try self.writeVarUint64(zigzagged);
    }

    /// Write an Uint8 integer.
    pub inline fn writeU8(self: *Self, value: u8) !void {
        try self.writeByte(value);
    }

    /// Write an Int8 integer.
    pub inline fn writeI8(self: *Self, value: i8) !void {
        try self.writeByte(@bitCast(value));
    }

    /// Write an Uint16 integer.
    pub inline fn writeU16(self: *Self, value: u16, endian: Endian) !void {
        std.debug.assert(self.offset + 2 <= self.bytes.len);
        std.mem.writeInt(u16, self.bytes[self.offset..][0..2], value, endian);
        self.offset += 2;
    }

    /// Write an Int16 integer.
    pub inline fn writeI16(self: *Self, value: i16, endian: Endian) !void {
        try self.writeU16(@bitCast(value), endian);
    }

    /// Write a Uint32 integer.
    pub inline fn writeU32(self: *Self, value: u32, endian: Endian) !void {
        std.debug.assert(self.offset + 4 <= self.bytes.len);
        std.mem.writeInt(u32, self.bytes[self.offset..][0..4], value, endian);
        self.offset += 4;
    }

    /// Write an Int32 integer.
    pub inline fn writeI32(self: *Self, value: i32, endian: Endian) !void {
        try self.writeU32(@bitCast(value), endian);
    }

    /// Write an Uint64 integer.
    pub inline fn writeU64(self: *Self, value: u64, endian: Endian) !void {
        std.debug.assert(self.offset + 8 <= self.bytes.len);
        std.mem.writeInt(u64, self.bytes[self.offset..][0..8], value, endian);
        self.offset += 8;
    }

    /// Write an Int64 integer.
    pub inline fn writeI64(self: *Self, value: i64, endian: Endian) !void {
        try self.writeU64(@bitCast(value), endian);
    }

    // 24 bit integers are some weird part of Minecraft/Raknet.

    /// Write Uint24 integer
    pub inline fn writeU24(self: *Self, value: u24, endian: Endian) !void {
        std.debug.assert(self.offset + 3 <= self.bytes.len);

        std.mem.writeInt(u24, self.bytes[self.offset..][0..3], value, endian);
        self.offset += 3;
    }

    /// Write Int24 integer
    pub inline fn writeI24(self: *Self, value: i24, endian: Endian) !void {
        try self.writeU24(@bitCast(value), endian);
    }

    /// Writes a slice of bytes to the stream.
    pub inline fn writeBytes(self: *Self, bytes: []const u8) !void {
        std.debug.assert(self.offset + bytes.len <= self.bytes.len);

        @memcpy(self.bytes[self.offset .. self.offset + bytes.len], bytes);
        self.offset += bytes.len;
    }

    /// Reads a slice of bytes from the stream.
    pub inline fn readBytes(self: *Self, length: usize) ![]u8 {
        if (self.offset + length > self.bytes.len) return error.EndOfStream;

        const value = self.bytes[self.offset .. self.offset + length];
        self.offset += length;

        return value;
    }

    /// Read a Uint8 integer.
    pub inline fn readU8(self: *Self) !u8 {
        if (self.offset >= self.bytes.len) return error.EndOfStream;
        const value = self.bytes[self.offset];
        self.offset += 1;

        return value;
    }

    /// Read an Int8 integer.
    pub inline fn readI8(self: *Self) !i8 {
        return @bitCast(try self.readU8());
    }

    /// Read an Uint16 integer.
    pub inline fn readU16(self: *Self, endian: Endian) !u16 {
        if (2 > self.bytes.len - self.offset) {
            return error.EndOfStream;
        }

        const value = std.mem.readInt(u16, self.bytes[self.offset..][0..2], endian);
        self.offset += 2;

        return value;
    }

    /// Read an Int16 integer.
    pub inline fn readI16(self: *Self, endian: Endian) !i16 {
        return @bitCast(try self.readU16(endian));
    }

    /// Read an Uint24 integer.
    pub inline fn readU24(self: *Self, endian: Endian) !u24 {
        if (3 > self.bytes.len - self.offset) {
            return error.EndOfStream;
        }

        const value = std.mem.readInt(u24, self.bytes[self.offset..][0..3], endian);
        self.offset += 3;

        return value;
    }

    /// Read an Uint32 integer.
    pub inline fn readU32(self: *Self, endian: Endian) !u32 {
        if (4 > self.bytes.len - self.offset) {
            return error.EndOfStream;
        }

        const value = std.mem.readInt(u32, self.bytes[self.offset..][0..4], endian);
        self.offset += 4;

        return value;
    }

    /// Read an Int32 integer.
    pub inline fn readI32(self: *Self, endian: Endian) !i32 {
        return @bitCast(try self.readU32(endian));
    }

    /// Reads a Uint32 VarInt.
    pub inline fn readVarUint32(self: *Self) !u32 {
        var result: u32 = 0;
        var shift: u5 = 0;
        var bytes_read: u8 = 0;

        while (true) {
            if (bytes_read >= 5) {
                return error.VarIntTooBig;
            }

            const byte = try self.readU8();
            result |= @as(u32, byte & 0x7f) << shift;

            if ((byte & 0x80) == 0) {
                return result;
            }

            shift += 7;
            bytes_read += 1;
        }
    }

    /// Reads a signed Int32 VarInt.
    pub inline fn readVarInt32(self: *Self) !i32 {
        const value = try self.readVarUint32();
        return @bitCast(value);
    }

    /// Read an Uint64 integer.
    pub inline fn readU64(self: *Self, endian: Endian) !u64 {
        if (self.offset + 8 > self.bytes.len) return error.EndOfStream;

        const value = std.mem.readInt(u64, self.bytes[self.offset..][0..8], endian);
        self.offset += 8;

        return value;
    }

    /// Read an Int64 integer.
    pub inline fn readI64(self: *Self, endian: Endian) !i64 {
        return @bitCast(try self.readU64(endian));
    }

    /// Write a String with Uint16 length.
    pub inline fn writeString16(self: *Self, value: []const u8, endian: Endian) !void {
        if (value.len > std.math.maxInt(u16)) {
            return error.StringTooLong;
        }

        try self.writeU16(@intCast(value.len), endian);
        try self.writeBytes(value);
    }

    /// Read a String with Uint16 length.
    pub inline fn readString16(self: *Self, endian: Endian) ![]u8 {
        const length = try self.readU16(endian);
        return try self.readBytes(length);
    }

    /// Write a String with Uint32 length.
    pub inline fn writeString32(self: *Self, value: []const u8, endian: Endian) !void {
        if (value.len > std.math.maxInt(u32)) {
            return error.StringTooLong;
        }

        try self.writeU32(@intCast(value.len), endian);
        try self.writeBytes(value);
    }

    /// Read a String with Uint32 length.
    pub inline fn readString32(self: *Self, endian: Endian) ![]u8 {
        const length = try self.readU32(endian);
        return try self.readBytes(length);
    }

    /// Write a String with Uint32 length.
    pub inline fn writeVarString(self: *Self, value: []const u8) !void {
        if (value.len > std.math.maxInt(u32)) {
            return error.StringTooLong;
        }

        try self.writeVarUint32(@intCast(value.len));
        try self.writeBytes(value);
    }

    /// Read a String with VarUint32 length.
    pub inline fn readVarString(self: *Self) ![]u8 {
        const length = try self.readVarUint32();
        return try self.readBytes(length);
    }

    pub fn getBuffer(self: *Self) []u8 {
        return self.bytes[0..self.offset];
    }

    /// Read a Float16.
    pub inline fn readF16(self: *Self, endian: Endian) !f16 {
        return @bitCast(try self.readU16(endian));
    }

    /// Write a Float16.
    pub inline fn writeF16(self: *Self, value: f16, endian: Endian) !void {
        try self.writeU16(@bitCast(value), endian);
    }

    /// Read a Float32.
    pub inline fn readF32(self: *Self, endian: Endian) !f32 {
        return @bitCast(try self.readU32(endian));
    }

    /// Write a Float32.
    pub inline fn writeF32(self: *Self, value: f32, endian: Endian) !void {
        try self.writeU32(@bitCast(value), endian);
    }

    /// Read a Float64.
    pub inline fn readF64(self: *Self, endian: Endian) !f64 {
        return @bitCast(try self.readU64(endian));
    }

    /// Write a Float64.
    pub inline fn writeF64(self: *Self, value: f64, endian: Endian) !void {
        try self.writeU64(@bitCast(value), endian);
    }

    /// Reads a Uint64 VarInt.
    pub inline fn readVarUint64(self: *Self) !u64 {
        var result: u64 = 0;
        var shift: u6 = 0;
        var bytes_read: u8 = 0;

        while (true) {
            if (bytes_read >= 10) {
                return error.VarIntTooBig;
            }

            const byte = try self.readU8();

            result |= @as(u64, byte & 0x7F) << shift;
            bytes_read += 1;

            if ((byte & 0x80) == 0) {
                return result;
            }

            shift += 7;
        }
    }

    /// Reads a signed Int64 VarInt. Signed VarInts are ZigZag decoded.
    pub inline fn readVarInt64(self: *Self) !i64 {
        const value = try self.readVarUint64();

        const decoded = (value >> 1) ^ (0 -% (value & 1));
        return @bitCast(decoded);
    }

    pub inline fn readUuid(self: *Self) ![16]u8 {
        const src = try self.readBytes(16);

        var uuid: [16]u8 = undefined;
        @memcpy(&uuid, src);

        std.mem.reverse(u8, uuid[0..8]);
        std.mem.reverse(u8, uuid[8..16]);

        return uuid;
    }

    pub inline fn writeUuid(self: *Self, uuid: [16]u8) !void {
        var out = uuid;

        std.mem.reverse(u8, out[0..8]);
        std.mem.reverse(u8, out[8..16]);

        try self.writeBytes(&out);
    }

    pub fn readVarUint128(self: *Self) !u128 {
        var value: u128 = 0;
        var shift: u7 = 0;

        while (true) {
            const byte = try self.readU8();

            value |= @as(u128, byte & 0x7f) << shift;

            if ((byte & 0x80) == 0) {
                return value;
            }

            shift += 7;

            if (shift >= 128) {
                return error.VarIntTooBig;
            }
        }
    }

    pub fn writeVarUint128(self: *Self, value: u128) !void {
        var remaining = value;

        while (remaining >= 0x80) {
            try self.writeU8(@as(u8, @truncate(remaining)) | 0x80);
            remaining >>= 7;
        }

        try self.writeU8(@truncate(remaining));
    }
};

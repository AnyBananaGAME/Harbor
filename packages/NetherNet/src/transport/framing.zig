const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;

pub const HeaderSize = 1;

pub const Error = error{
    EmptyMessage,
    FragmentSequence,
    InvalidUnreliableFragment,
    NoSpace,
};

pub const Reassembler = struct {
    storage: []u8,
    length: usize = 0,
    remaining: ?u8 = null,

    pub fn init(storage: []u8) Reassembler {
        return .{ .storage = storage };
    }

    pub fn reset(self: *Reassembler) void {
        self.length = 0;
        self.remaining = null;
    }

    pub fn push(self: *Reassembler, message: []const u8) Error!?[]u8 {
        if (message.len == 0) return error.EmptyMessage;

        var stream = BinaryStream.init(@constCast(message), 0);
        const header = stream.readU8() catch return error.EmptyMessage;

        if (self.remaining) |remaining| {
            if (header != remaining -| 1) return error.FragmentSequence;
        }

        const payload = stream.readBytes(message.len - HeaderSize) catch {
            return error.EmptyMessage;
        };

        if (payload.len > self.storage.len -| self.length) return error.NoSpace;

        @memcpy(self.storage[self.length .. self.length + payload.len], payload);
        self.length += payload.len;

        if (header != 0) {
            self.remaining = header;
            return null;
        }

        const result = self.storage[0..self.length];
        self.reset();
        return result;
    }

    pub fn write(_: *const Reassembler, out: []u8, payload: []const u8, remaining_fragments: u8) Error![]u8 {
        if (out.len < payload.len + HeaderSize) return error.NoSpace;

        var stream = BinaryStream.init(out, 0);
        try stream.writeU8(remaining_fragments);
        try stream.writeBytes(payload);
        return stream.getBuffer();
    }

    pub fn validateUnreliable(_: *const Reassembler, message: []const u8) Error![]const u8 {
        if (message.len == 0) return error.EmptyMessage;

        var stream = BinaryStream.init(@constCast(message), 0);
        const header = stream.readU8() catch return error.EmptyMessage;
        if (header != 0) return error.InvalidUnreliableFragment;

        return stream.readBytes(message.len - HeaderSize) catch error.EmptyMessage;
    }
};

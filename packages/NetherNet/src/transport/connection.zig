const Framing = @import("framing.zig").Reassembler;
const native = @import("../native/libdatachannel.zig");

pub const Error = error{
    ReliableChannelUnavailable,
    UnreliableChannelUnavailable,
    MessageTooLarge,
};

pub const Connection = struct {
    reliable: ?c_int = null,
    unreliable: ?c_int = null,
    reassembler: Framing,

    pub fn init(packet_storage: []u8) Connection {
        return .{
            .reassembler = .init(packet_storage),
        };
    }

    pub fn bindReliable(self: *Connection, stream: c_int) void {
        self.reliable = stream;
    }

    pub fn bindUnreliable(self: *Connection, stream: c_int) void {
        self.unreliable = stream;
    }

    pub fn receive(self: *Connection, stream: c_int, bytes: []const u8) !?[]u8 {
        if (self.reliable) |reliable| {
            if (stream == reliable) return self.reassembler.push(bytes);
        }

        if (self.unreliable) |unreliable| {
            if (stream == unreliable) return self.reassembler.validateUnreliable(bytes);
        }

        return null;
    }

    pub fn send(self: *const Connection, out: []u8, bytes: []const u8) !void {
        const stream = self.reliable orelse return error.ReliableChannelUnavailable;
        if (bytes.len == 0) return error.MessageTooLarge;
        if (out.len < 2) return error.MessageTooLarge;
        const chunk_size = out.len - 1;
        var offset: usize = 0;
        while (offset < bytes.len) {
            const chunk = @min(chunk_size, bytes.len - offset);
            const remaining = (bytes.len - offset - chunk + chunk_size - 1) / chunk_size;
            const frame = try self.reassembler.write(out, bytes[offset .. offset + chunk], @intCast(remaining));
            try native.check(native.nethernet_datachannel_send(stream, frame.ptr, @intCast(frame.len)));
            offset += chunk;
        }
    }

    pub fn sendUnreliable(self: *const Connection, out: []u8, bytes: []const u8) !void {
        const stream = self.unreliable orelse return error.UnreliableChannelUnavailable;
        const frame = try self.reassembler.write(out, bytes, 0);
        try native.check(native.nethernet_datachannel_send(stream, frame.ptr, @intCast(frame.len)));
    }
};

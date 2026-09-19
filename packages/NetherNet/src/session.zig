const std = @import("std");
const native = @import("native/libdatachannel.zig");
const BinaryStream = @import("binarystream").BinaryStream;
const Framing = @import("transport/framing.zig").Reassembler;

pub const Handler = *const fn (context: ?*anyopaque, session: *Session, channel: c_int, data: []const u8) void;

pub const OutgoingPacket = struct {
    id: u32,
    payload: []const u8,
};

pub const Session = struct {
    io: std.Io,
    connection: native.Connection,
    reliable: ?c_int = null,
    unreliable: ?c_int = null,
    handler: Handler,
    handler_context: ?*anyopaque = null,
    callback_state: native.Callbacks = .{},
    release: ?*const fn (?*anyopaque, *Session) void = null,
    release_context: ?*anyopaque = null,
    released: bool = false,
    pool_slot: ?*?Session = null,
    compression: ?u8 = null,
    send_mutex: std.Io.Mutex = .init,
    frame_storage: [128 * 1024]u8 = undefined,
    reassembler: Framing,

    fn dataChannel(channel: c_int, label: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        const name = std.mem.span(label);
        if (std.mem.eql(u8, name, "ReliableDataChannel")) session.reliable = channel;
        if (std.mem.eql(u8, name, "UnreliableDataChannel")) session.unreliable = channel;
    }

    fn opened(channel: c_int, user_data: ?*anyopaque) callconv(.c) void {
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        session.handler(session.handler_context, session, channel, &.{});
    }

    fn closed(_: c_int, _: ?*anyopaque) callconv(.c) void {}

    fn stateChanged(state: c_int, user_data: ?*anyopaque) callconv(.c) void {
        if (state != 5) return;
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        if (session.released) return;
        session.released = true;
        if (session.release) |release| release(session.release_context, session);
    }

    fn message(channel: c_int, data: [*]const u8, size: c_int, user_data: ?*anyopaque) callconv(.c) void {
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        if (size >= 0) {
            const frame = data[0..@intCast(size)];
            const payload = if (session.reliable == channel)
                session.reassembler.push(frame) catch return
            else if (session.unreliable == channel)
                session.reassembler.validateUnreliable(frame) catch return
            else
                return;
            if (payload) |complete| {
                session.handler(session.handler_context, session, channel, complete);
            }
        }
    }

    pub fn callbacks(self: *Session) native.Callbacks {
        return .{
            .data_channel = dataChannel,
            .open = opened,
            .closed = closed,
            .message = message,
            .state = stateChanged,
            .user_data = self,
        };
    }

    pub fn initReassembler(self: *Session) void {
        self.reassembler = .init(&self.frame_storage);
    }

    pub fn send(self: *Session, channel: c_int, packet_id: u32, payload: []const u8) !void {
        try self.send_mutex.lock(self.io);
        defer self.send_mutex.unlock(self.io);

        var packet: [128 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.init(&packet, 0);
        var body: [128 * 1024]u8 = undefined;
        var body_stream = BinaryStream.init(&body, 0);
        try body_stream.writeVarUint32(packet_id);
        try body_stream.writeBytes(payload);
        try packet_stream.writeVarUint32(@intCast(body_stream.getBuffer().len));
        try packet_stream.writeBytes(body_stream.getBuffer());

        const compression = self.compression orelse 0xFF;
        var compressed: [128 * 1024]u8 = undefined;
        var packet_data = packet_stream.getBuffer();
        if (compression == 0) {
            var output = std.Io.Writer.fixed(&compressed);
            var window: [std.compress.flate.max_window_len]u8 = undefined;
            var compressor = try std.compress.flate.Compress.init(
                &output,
                &window,
                .raw,
                .fastest,
            );
            try compressor.writer.writeAll(packet_stream.getBuffer());
            try compressor.writer.flush();
            try compressor.finish();
            packet_data = compressed[0..output.end];
        } else if (compression != 0xFF) {
            return error.UnsupportedCompression;
        }

        var frame: [128 * 1024]u8 = undefined;
        var stream = BinaryStream.init(&frame, 0);

        try stream.writeU8(0);
        try stream.writeU8(compression);
        try stream.writeBytes(packet_data);

        try native.check(native.nethernet_datachannel_send(channel, stream.getBuffer().ptr, @intCast(stream.getBuffer().len)));
    }

    pub fn sendReliable(self: *Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.reliable orelse return error.ChannelNotOpen;
        return self.send(channel, packet_id, payload);
    }

    pub fn sendReliableBatch(self: *Session, packets: []const OutgoingPacket) !void {
        try self.send_mutex.lock(self.io);
        defer self.send_mutex.unlock(self.io);

        const channel = self.reliable orelse return error.ChannelNotOpen;
        var packet: [128 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.init(&packet, 0);
        var body: [128 * 1024]u8 = undefined;

        for (packets) |outgoing| {
            var body_stream = BinaryStream.init(&body, 0);
            try body_stream.writeVarUint32(outgoing.id);
            try body_stream.writeBytes(outgoing.payload);
            try packet_stream.writeVarUint32(@intCast(body_stream.getBuffer().len));
            try packet_stream.writeBytes(body_stream.getBuffer());
        }

        const compression = self.compression orelse 0xFF;
        var compressed: [128 * 1024]u8 = undefined;
        var packet_data = packet_stream.getBuffer();
        if (compression == 0) {
            var output = std.Io.Writer.fixed(&compressed);
            var window: [std.compress.flate.max_window_len]u8 = undefined;
            var compressor = try std.compress.flate.Compress.init(&output, &window, .raw, .fastest);
            try compressor.writer.writeAll(packet_data);
            try compressor.writer.flush();
            try compressor.finish();
            packet_data = compressed[0..output.end];

        } else if (compression != 0xFF) return error.UnsupportedCompression;

        var frame: [128 * 1024]u8 = undefined;
        var stream = BinaryStream.init(&frame, 0);
        try stream.writeU8(0);
        try stream.writeU8(compression);
        try stream.writeBytes(packet_data);
        const sent_frame = stream.getBuffer();
        try native.check(native.nethernet_datachannel_send(channel, sent_frame.ptr, @intCast(sent_frame.len)));
    }

    pub fn sendUncompressed(self: *Session, channel: c_int, packet_id: u32, payload: []const u8) !void {
        try self.send_mutex.lock(self.io);
        defer self.send_mutex.unlock(self.io);

        var packet: [128 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.init(&packet, 0);
        try packet_stream.writeVarUint32(packet_id);
        try packet_stream.writeBytes(payload);

        var frame: [128 * 1024]u8 = undefined;
        var stream = BinaryStream.init(&frame, 0);
        try stream.writeU8(0);
        try stream.writeVarUint32(@intCast(packet_stream.getBuffer().len));
        try stream.writeBytes(packet_stream.getBuffer());
        const sent_frame = stream.getBuffer();
        try native.check(native.nethernet_datachannel_send(channel, sent_frame.ptr, @intCast(sent_frame.len)));
    }

    pub fn sendReliableUncompressed(self: *Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.reliable orelse return error.ChannelNotOpen;
        try self.send_mutex.lock(self.io);
        defer self.send_mutex.unlock(self.io);

        var packet: [128 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.init(&packet, 0);
        try packet_stream.writeVarUint32(packet_id);
        try packet_stream.writeBytes(payload);

        var batch: [128 * 1024]u8 = undefined;
        var batch_stream = BinaryStream.init(&batch, 0);
        try batch_stream.writeVarUint32(@intCast(packet_stream.getBuffer().len));
        try batch_stream.writeBytes(packet_stream.getBuffer());

        var frame: [128 * 1024]u8 = undefined;
        var frame_stream = BinaryStream.init(&frame, 0);
        try frame_stream.writeU8(0);
        try frame_stream.writeU8(0xFF);
        try frame_stream.writeBytes(batch_stream.getBuffer());

        const sent_frame = frame_stream.getBuffer();
        try native.check(native.nethernet_datachannel_send(channel, sent_frame.ptr, @intCast(sent_frame.len)));
    }

    pub fn sendUnreliable(self: *Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.unreliable orelse return error.ChannelNotOpen;
        return self.send(channel, packet_id, payload);
    }

    pub fn sendUnreliableUncompressed(self: *const Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.unreliable orelse return error.ChannelNotOpen;
        return self.sendUncompressed(channel, packet_id, payload);
    }
};

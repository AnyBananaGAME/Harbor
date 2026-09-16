const std = @import("std");
const native = @import("native/libdatachannel.zig");
const BinaryStream = @import("binarystream").BinaryStream;
const Framing = @import("transport/framing.zig").Reassembler;

pub const Handler = *const fn (context: ?*anyopaque, session: *Session, channel: c_int, data: []const u8) void;

pub const Session = struct {
    connection: native.Connection,
    reliable: ?c_int = null,
    unreliable: ?c_int = null,
    handler: Handler,
    handler_context: ?*anyopaque = null,
    callback_state: native.Callbacks = .{},
    release: ?*const fn (?*anyopaque, *Session) void = null,
    release_context: ?*anyopaque = null,
    released: bool = false,
    compression: ?u8 = null,
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
            if (payload) |complete| session.handler(session.handler_context, session, channel, complete);
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

    pub fn send(self: *const Session, channel: c_int, packet_id: u32, payload: []const u8) !void {
        _ = self;
        var packet: [128 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.init(&packet, 0);
        try packet_stream.writeVarUint32(packet_id);
        try packet_stream.writeBytes(payload);

        var frame: [128 * 1024]u8 = undefined;
        var stream = BinaryStream.init(&frame, 0);

        try stream.writeU8(0);
        try stream.writeU8(0);
        try stream.writeVarUint32(@intCast(packet_stream.getBuffer().len));
        try stream.writeBytes(packet_stream.getBuffer());

        try native.check(native.nethernet_datachannel_send(channel, stream.getBuffer().ptr, @intCast(stream.getBuffer().len)));
    }

    pub fn sendReliable(self: *const Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.reliable orelse return error.ChannelNotOpen;
        return self.send(channel, packet_id, payload);
    }

    pub fn sendUncompressed(self: *const Session, channel: c_int, packet_id: u32, payload: []const u8) !void {
        _ = self;
        var packet: [128 * 1024]u8 = undefined;
        var packet_stream = BinaryStream.init(&packet, 0);
        try packet_stream.writeVarUint32(packet_id);
        try packet_stream.writeBytes(payload);

        var frame: [128 * 1024]u8 = undefined;
        var stream = BinaryStream.init(&frame, 0);
        try stream.writeU8(0);
        try stream.writeVarUint32(@intCast(packet_stream.getBuffer().len));
        try stream.writeBytes(packet_stream.getBuffer());
        try native.check(native.nethernet_datachannel_send(channel, stream.getBuffer().ptr, @intCast(stream.getBuffer().len)));
    }

    pub fn sendReliableUncompressed(self: *const Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.reliable orelse return error.ChannelNotOpen;
        return self.sendUncompressed(channel, packet_id, payload);
    }

    pub fn sendUnreliable(self: *const Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.unreliable orelse return error.ChannelNotOpen;
        return self.send(channel, packet_id, payload);
    }

    pub fn sendUnreliableUncompressed(self: *const Session, packet_id: u32, payload: []const u8) !void {
        const channel = self.unreliable orelse return error.ChannelNotOpen;
        return self.sendUncompressed(channel, packet_id, payload);
    }
};

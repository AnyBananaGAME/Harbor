const std = @import("std");
const native = @import("native/libdatachannel.zig");

pub const Handler = *const fn (session: *Session, channel: c_int, data: []const u8) void;

pub const Session = struct {
    connection: native.Connection,
    reliable: ?c_int = null,
    unreliable: ?c_int = null,
    handler: Handler,
    callback_state: native.Callbacks = .{},

    fn dataChannel(channel: c_int, label: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void {
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        const name = std.mem.span(label);
        if (std.mem.eql(u8, name, "ReliableDataChannel")) session.reliable = channel;
        if (std.mem.eql(u8, name, "UnreliableDataChannel")) session.unreliable = channel;
    }

    fn opened(channel: c_int, user_data: ?*anyopaque) callconv(.c) void {
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        session.handler(session, channel, &.{});
    }

    fn closed(_: c_int, _: ?*anyopaque) callconv(.c) void {}

    fn message(channel: c_int, data: [*]const u8, size: c_int, user_data: ?*anyopaque) callconv(.c) void {
        const session: *Session = @ptrCast(@alignCast(user_data.?));
        if (size >= 0) {
            session.handler(session, channel, data[0..@intCast(size)]);
        }
    }

    pub fn callbacks(self: *Session) native.Callbacks {
        return .{
            .data_channel = dataChannel,
            .open = opened,
            .closed = closed,
            .message = message,
            .user_data = self,
        };
    }
};

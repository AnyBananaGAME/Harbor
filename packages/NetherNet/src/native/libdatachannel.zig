const std = @import("std");

pub const Peer = opaque {};

pub const DescriptionFn = *const fn (sdp: [*:0]const u8, kind: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void;
pub const CandidateFn = *const fn (candidate: [*:0]const u8, mid: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void;
pub const StateFn = *const fn (state: c_int, user_data: ?*anyopaque) callconv(.c) void;
pub const DataChannelFn = *const fn (channel: c_int, label: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void;
pub const OpenFn = *const fn (channel: c_int, user_data: ?*anyopaque) callconv(.c) void;
pub const ClosedFn = *const fn (channel: c_int, user_data: ?*anyopaque) callconv(.c) void;
pub const MessageFn = *const fn (channel: c_int, data: [*]const u8, size: c_int, user_data: ?*anyopaque) callconv(.c) void;
pub const ErrorFn = *const fn (channel: c_int, message: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void;
pub const AnswerFn = *const fn (offer: [*:0]const u8, offer_size: c_int, answer: [*]u8, answer_size: c_int, user_data: ?*anyopaque) callconv(.c) c_int;

pub const Callbacks = extern struct {
    description: ?DescriptionFn = null,
    candidate: ?CandidateFn = null,
    state: ?StateFn = null,
    data_channel: ?DataChannelFn = null,
    open: ?OpenFn = null,
    closed: ?ClosedFn = null,
    message: ?MessageFn = null,
    @"error": ?ErrorFn = null,
    user_data: ?*anyopaque = null,
};

pub extern fn nethernet_datachannel_create(bind_address: [*:0]const u8, port: u16) ?*Peer;
pub extern fn nethernet_datachannel_set_offer(peer: *Peer, offer: [*:0]const u8) c_int;
pub extern fn nethernet_datachannel_create_answer(peer: *Peer, buffer: [*]u8, size: c_int) c_int;
pub extern fn nethernet_datachannel_set_callbacks(peer: *Peer, callbacks: *const Callbacks) c_int;
pub extern fn nethernet_datachannel_send(channel: c_int, data: [*]const u8, size: c_int) c_int;
pub extern fn nethernet_datachannel_channel_label(channel: c_int, buffer: [*]u8, size: c_int) c_int;
pub extern fn nethernet_datachannel_close(peer: *Peer) void;
pub extern fn nethernet_https_start(bind_address: [*:0]const u8, port: u16, certificate_path: [*:0]const u8, key_path: [*:0]const u8, identity_key_path: [*:0]const u8, answer: AnswerFn, user_data: ?*anyopaque) c_int;

pub const Error = error{
    InvalidConfiguration,
    OperationFailed,
    BufferTooSmall,
};

pub const Connection = struct {
    peer: *Peer,

    pub fn init(bind_address: [:0]const u8, port: u16) Error!Connection {
        return .{ .peer = nethernet_datachannel_create(bind_address.ptr, port) orelse return error.OperationFailed };
    }

    pub fn setOffer(self: *Connection, offer: [:0]const u8) Error!void {
        try check(nethernet_datachannel_set_offer(self.peer, offer.ptr));
    }

    pub fn createAnswer(self: *Connection, buffer: []u8) Error![]u8 {
        const length = nethernet_datachannel_create_answer(self.peer, buffer.ptr, @intCast(buffer.len));
        if (length == -4) return error.BufferTooSmall;
        if (length < 0) return error.OperationFailed;
        if (length == 0) return buffer[0..0];
        return buffer[0..@intCast(length - 1)];
    }

    pub fn setCallbacks(self: *Connection, callbacks: *const Callbacks) Error!void {
        try check(nethernet_datachannel_set_callbacks(self.peer, callbacks));
    }

    pub fn close(self: *Connection) void {
        nethernet_datachannel_close(self.peer);
    }
};

pub fn check(result: c_int) Error!void {
    switch (result) {
        0 => {},
        -4 => return error.BufferTooSmall,
        -1 => return error.InvalidConfiguration,
        else => return error.OperationFailed,
    }
}

test {
    std.testing.refAllDecls(@This());
}

const std = @import("std");
const PeerConnection = @import("transport/peer_connection.zig").PeerConnection;
const State = @import("transport/peer_connection.zig").State;
const DataChannel = @import("transport/channel.zig").DataChannel;
const Connection = @import("transport/connection.zig").Connection;
const NetherNetChannel = @import("transport/nethernet_channel.zig").NetherNetChannel;
const Negotiation = @import("signaling/negotiation.zig").Negotiation;
const Signaler = @import("signaling/signaler.zig").Signaler;
const Signal = @import("signaling/signal.zig").Signal;
const constants = @import("constants.zig");

pub const Listener = struct {
    const Self = @This();

    signaler: Signaler,
    peer_factory_context: ?*anyopaque,
    create_peer: PeerFactory,
    connection_id: u64,
    network_id: []const u8,
    peer: ?PeerConnection = null,
    negotiation: ?Negotiation = null,
    connection: ?Connection = null,
    reliable_channel: ?NetherNetChannel = null,
    unreliable_channel: ?NetherNetChannel = null,
    state: State = .new,
    connected_context: ?*anyopaque = null,
    connected_callback: ?ConnectedCallback = null,
    failed_context: ?*anyopaque = null,
    failed_callback: ?FailedCallback = null,

    pub const PeerFactory = *const fn (?*anyopaque) anyerror!PeerConnection;
    pub const ConnectedCallback = *const fn (?*anyopaque, *Connection) void;
    pub const FailedCallback = *const fn (?*anyopaque, anyerror) void;

    pub fn init(
        signaler: Signaler,
        peer_factory_context: ?*anyopaque,
        create_peer: PeerFactory,
        connection_id: u64,
        network_id: []const u8,
    ) Self {
        return .{
            .signaler = signaler,
            .peer_factory_context = peer_factory_context,
            .create_peer = create_peer,
            .connection_id = connection_id,
            .network_id = network_id,
        };
    }

    pub fn onConnected(self: *Self, context: ?*anyopaque, callback: ConnectedCallback) void {
        self.connected_context = context;
        self.connected_callback = callback;
    }

    pub fn onFailed(self: *Self, context: ?*anyopaque, callback: FailedCallback) void {
        self.failed_context = context;
        self.failed_callback = callback;
    }

    pub fn listen(self: *Self) void {
        self.signaler.onSignal(self, handleSignal);
    }

    pub fn close(self: *Self) void {
        if (self.state == .closed) return;
        if (self.peer) |peer| peer.close();
        self.peer = null;
        self.connection = null;
        self.reliable_channel = null;
        self.unreliable_channel = null;
        self.negotiation = null;
        self.signaler.close();
        self.state = .closed;
    }

    pub fn getState(self: *const Self) State {
        return self.state;
    }

    fn handleSignal(context: ?*anyopaque, signal: Signal) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        if (self.state == .closed) return;
        if (signal.type != .offer) return;
        if ((self.connection_id != 0 and signal.connection_id != self.connection_id) or
            !std.mem.eql(u8, signal.network_id, self.network_id)) return;
        if (self.peer != null) return;

        const peer = self.create_peer(self.peer_factory_context) catch |err| {
            self.fail(err);
            return;
        };
        if (self.connection_id == 0) self.connection_id = signal.connection_id;
        self.peer = peer;
        peer.onStateChange(self, handleStateChange);
        peer.onDataChannel(self, handleDataChannel);
        self.negotiation = Negotiation.init(
            peer,
            self.signaler,
            .controlled,
            self.connection_id,
            self.network_id,
        );
        self.state = .connecting;
        self.negotiation.?.handleSignal(signal) catch |err| self.fail(err);
    }

    fn handleDataChannel(context: ?*anyopaque, channel: DataChannel) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        if (std.mem.eql(u8, channel.getLabel(), constants.ReliableChannel)) {
            self.reliable_channel = NetherNetChannel.init(channel);
        } else if (std.mem.eql(u8, channel.getLabel(), constants.UnreliableChannel)) {
            self.unreliable_channel = NetherNetChannel.init(channel);
        } else {
            return;
        }
        if (self.reliable_channel) |reliable| {
            self.connection = Connection.init(reliable, self.unreliable_channel);
        }
        self.notifyConnected();
    }

    fn handleStateChange(context: ?*anyopaque, state: State) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        self.state = state;
        switch (state) {
            .connected => self.notifyConnected(),
            .failed => self.fail(error.PeerConnectionFailed),
            .closed => {
                self.peer = null;
                self.connection = null;
                self.reliable_channel = null;
                self.unreliable_channel = null;
                self.negotiation = null;
            },
            else => {},
        }
    }

    fn notifyConnected(self: *Self) void {
        if (self.state != .connected) return;
        const connection = &(self.connection orelse return);
        if (self.unreliable_channel == null) return;
        if (self.connected_callback) |callback| {
            const callback_fn = callback;
            self.connected_callback = null;
            callback_fn(self.connected_context, connection);
        }
    }

    fn fail(self: *Self, err: anyerror) void {
        if (self.state == .failed or self.state == .closed) return;
        self.state = .failed;
        if (self.peer) |peer| peer.close();
        self.peer = null;
        self.connection = null;
        self.reliable_channel = null;
        self.unreliable_channel = null;
        self.negotiation = null;
        if (self.failed_callback) |callback| callback(self.failed_context, err);
    }
};

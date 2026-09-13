const std = @import("std");
const PeerConnection = @import("transport/peer_connection.zig").PeerConnection;
const State = @import("transport/peer_connection.zig").State;
const Negotiation = @import("signaling/negotiation.zig").Negotiation;
const Signaler = @import("signaling/signaler.zig").Signaler;
const Signal = @import("signaling/signal.zig").Signal;
const Connection = @import("transport/connection.zig").Connection;
const NetherNetChannel = @import("transport/nethernet_channel.zig").NetherNetChannel;
const DataChannel = @import("transport/channel.zig").DataChannel;
const constants = @import("constants.zig");

pub const Dialer = struct {
    const Self = @This();

    signaler: Signaler,

    peer_factory_context: ?*anyopaque,
    create_peer: PeerFactory,

    peer: ?PeerConnection = null,
    connection: ?Connection = null,
    negotiation: ?Negotiation = null,

    connection_id: u64,
    remote_network_id: []const u8,

    state: State = .new,

    connected_context: ?*anyopaque = null,
    failed_context: ?*anyopaque = null,
    connected_callback: ?ConnectedCallback = null,
    failed_callback: ?FailedCallback = null,
    connected_notified: bool = false,

    pub const PeerFactory = *const fn (
        context: ?*anyopaque,
    ) anyerror!PeerConnection;

    pub const ConnectedCallback = *const fn (
        context: ?*anyopaque,
        connection: *Connection,
    ) void;

    pub const FailedCallback = *const fn (
        context: ?*anyopaque,
        err: anyerror,
    ) void;

    pub fn init(
        signaler: Signaler,
        peer_factory_context: ?*anyopaque,
        create_peer: PeerFactory,
        connection_id: u64,
        remote_network_id: []const u8,
    ) Self {
        return .{
            .signaler = signaler,

            .peer_factory_context = peer_factory_context,
            .create_peer = create_peer,

            .connection_id = connection_id,
            .remote_network_id = remote_network_id,
        };
    }

    /// ```zig
    /// const ConnectedCallback = *const fn (
    ///     context: ?*anyopaque,
    ///     connection: *Connection,
    /// ) void
    pub fn onConnected(
        self: *Self,
        context: ?*anyopaque,
        callback: ConnectedCallback,
    ) void {
        self.connected_context = context;
        self.connected_callback = callback;
    }

    /// ```zig
    /// const FailedCallback = *const fn (
    ///    context: ?*anyopaque,
    ///    err: anyerror,
    /// ) void
    pub fn onFailed(
        self: *Self,
        context: ?*anyopaque,
        callback: FailedCallback,
    ) void {
        self.failed_context = context;
        self.failed_callback = callback;
    }

    pub fn connect(self: *Self) !void {
        if (self.state == .connecting or self.state == .connected)
            return error.AlreadyConnecting;

        if (self.state == .closed)
            return error.Closed;

        const peer = try self.create_peer(
            self.peer_factory_context,
        );

        self.peer = peer;

        const reliable = peer.createDataChannel(constants.ReliableChannel, true) catch |err| {
            self.fail(err);
            return err;
        };
        const unreliable = peer.createDataChannel(constants.UnreliableChannel, false) catch |err| {
            self.fail(err);
            return err;
        };
        self.connection = Connection.init(
            NetherNetChannel.init(reliable),
            NetherNetChannel.init(unreliable),
        );
        self.connected_notified = false;

        peer.onIceCandidate(
            self,
            handleIceCandidate,
        );

        peer.onStateChange(
            self,
            handleStateChange,
        );

        peer.onDataChannel(self, handleDataChannel);

        self.signaler.onSignal(
            self,
            handleSignal,
        );

        self.negotiation = Negotiation.init(
            peer,
            self.signaler,
            .controlling,
            self.connection_id,
            self.remote_network_id,
        );

        self.state = .connecting;

        const offer = peer.createOffer() catch |err| {
            self.fail(err);
            return err;
        };

        peer.setLocalDescription(offer) catch |err| {
            self.fail(err);
            return err;
        };

        self.signaler.send(.{
            .type = .offer,
            .connection_id = self.connection_id,
            .network_id = self.remote_network_id,
            .data = (peer.localDescription() orelse offer).sdp,
        }) catch |err| {
            self.fail(err);
            return err;
        };
    }

    pub fn close(self: *Self) void {
        if (self.state == .closed)
            return;

        if (self.peer) |peer| {
            peer.close();
            self.peer = null;
        }

        self.connection = null;

        self.negotiation = null;
        self.signaler.close();
        self.state = .closed;
    }

    pub fn getState(self: *const Self) State {
        return self.state;
    }

    fn handleSignal(
        context: ?*anyopaque,
        signal: Signal,
    ) void {
        const self: *Self =
            @ptrCast(@alignCast(context.?));

        if (self.state != .connecting and self.state != .connected)
            return;

        if (signal.connection_id != self.connection_id or
            !std.mem.eql(u8, signal.network_id, self.remote_network_id))
            return;

        var negotiation = &(self.negotiation orelse return);

        negotiation.handleSignal(signal) catch |err| {
            self.fail(err);
        };
    }

    fn handleIceCandidate(
        context: ?*anyopaque,
        candidate: []const u8,
    ) void {
        const self: *Self =
            @ptrCast(@alignCast(context.?));

        self.signaler.send(.{
            .type = .candidate,
            .connection_id = self.connection_id,
            .network_id = self.remote_network_id,
            .data = candidate,
        }) catch |err| {
            self.fail(err);
        };
    }

    fn handleStateChange(
        context: ?*anyopaque,
        state: State,
    ) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        self.state = state;

        switch (state) {
            .connected => {
                _ = self.connection orelse return;
                if (self.connected_notified) return;

                if (self.connected_callback) |callback| {
                    self.connected_notified = true;
                    callback(
                        self.connected_context,
                        &self.connection.?,
                    );
                }
            },
            .failed => {
                self.fail(error.PeerConnectionFailed);
            },
            .closed => {
                self.peer = null;
                self.connection = null;
                self.negotiation = null;
            },
            else => {},
        }
    }

    fn fail(
        self: *Self,
        err: anyerror,
    ) void {
        if (self.state == .failed or self.state == .closed)
            return;

        self.state = .failed;

        if (self.peer) |peer| {
            peer.close();
            self.peer = null;
        }

        self.connection = null;

        self.negotiation = null;

        if (self.failed_callback) |callback| {
            callback(
                self.failed_context,
                err,
            );
        }
    }

    fn handleDataChannel(context: ?*anyopaque, channel: DataChannel) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        const connection = &(self.connection orelse return);
        if (std.mem.eql(u8, channel.getLabel(), constants.ReliableChannel)) {
            connection.reliable = NetherNetChannel.init(channel);
        } else if (std.mem.eql(u8, channel.getLabel(), constants.UnreliableChannel)) {
            connection.unreliable = NetherNetChannel.init(channel);
        }
    }
};

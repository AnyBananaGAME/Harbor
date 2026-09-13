const std = @import("std");
const webrtc = @import("webrtc");
const PeerConnection = @import("../transport/peer_connection.zig").PeerConnection;
const Description = @import("../transport/peer_connection.zig").Description;
const DescriptionType = @import("../transport/peer_connection.zig").DescriptionType;
const State = @import("../transport/peer_connection.zig").State;
const DataChannel = @import("../transport/channel.zig").DataChannel;

const Handler = webrtc.PeerConnectionHandler;
const IceCandidateCallback = @FieldType(Handler.VTable, "onIceCandidate");
const IceCandidateParam = @typeInfo(@typeInfo(IceCandidateCallback).pointer.child).@"fn".params[1].type.?;
const IceCandidate = @typeInfo(IceCandidateParam).optional.child;
const DataCallback = @typeInfo(@TypeOf(webrtc.DataChannel.registerCallback)).@"fn".params[2].type.?;
const DataEvent = @typeInfo(@typeInfo(DataCallback).pointer.child).@"fn".params[2].type.?;

pub const Factory = struct {
    io: std.Io,
    allocator: std.mem.Allocator,

    pub fn createPeer(context: ?*anyopaque) !PeerConnection {
        const self: *Factory = @ptrCast(@alignCast(context.?));
        const peer = try self.allocator.create(Peer);
        errdefer self.allocator.destroy(peer);
        try peer.init(self.io, self.allocator);
        peer.peer.handler = Handler.init(peer, &handler_vtable);
        return peer.handle();
    }
};

const Peer = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    media_engine: webrtc.MediaEngine,
    peer: webrtc.PeerConnection,
    local_sdp: []const u8 = &. {},
    local_type: DescriptionType = .offer,
    ice_context: ?*anyopaque = null,
    ice_callback: ?PeerConnection.IceCandidateCallback = null,
    state_context: ?*anyopaque = null,
    state_callback: ?PeerConnection.StateCallback = null,
    data_context: ?*anyopaque = null,
    data_callback: ?PeerConnection.DataChannelCallback = null,
    channels: std.ArrayList(*Channel) = .empty,

    fn init(self: *Peer, io: std.Io, allocator: std.mem.Allocator) !void {
        self.* = .{
            .io = io,
            .allocator = allocator,
            .media_engine = webrtc.MediaEngine.init(.{}),
            .peer = undefined,
        };
        errdefer self.media_engine.deinit(allocator);
        self.peer = try webrtc.PeerConnection.init(io, allocator, .{
            .media_engine = &self.media_engine,
            .handler = null,
        });
    }

    fn handle(self: *Peer) PeerConnection {
        return .{ .ptr = self, .vtable = &peer_vtable };
    }

    fn deinit(self: *Peer) void {
        self.peer.deinit();
        for (self.channels.items) |channel| self.allocator.destroy(channel);
        self.channels.deinit(self.allocator);
        self.allocator.free(self.local_sdp);
        self.media_engine.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    fn refreshLocalDescription(self: *Peer) !void {
        const description = (try self.peer.getLocalDescription()) orelse return error.NoLocalDescription;
        self.allocator.free(self.local_sdp);
        self.local_sdp = description.sdp;
        self.local_type = switch (description.type) {
            .offer => .offer,
            .answer => .answer,
            else => return error.InvalidDescription,
        };
    }

    fn onIceCandidate(self: *Peer, context: ?*anyopaque, callback: PeerConnection.IceCandidateCallback) void {
        self.ice_context = context;
        self.ice_callback = callback;
    }

    fn onStateChange(self: *Peer, context: ?*anyopaque, callback: PeerConnection.StateCallback) void {
        self.state_context = context;
        self.state_callback = callback;
    }

    fn createDataChannel(self: *Peer, label: []const u8, reliable: bool) !DataChannel {
        const actual = try self.peer.createDataChannel(label, .{
                .ordered = reliable,
                .max_retransmits = if (reliable) 0 else 1,
            });
        return self.wrapChannel(actual);
    }

    fn wrapChannel(self: *Peer, actual: *webrtc.DataChannel) !DataChannel {
        const channel = try self.allocator.create(Channel);
        errdefer self.allocator.destroy(channel);
        channel.* = .{ .peer = self, .channel = actual };
        try self.channels.append(self.allocator, channel);
        return channel.handle();
    }
};

const Channel = struct {
    peer: *Peer,
    channel: *webrtc.DataChannel,
    message_context: ?*anyopaque = null,
    message_callback: ?DataChannel.MessageCallback = null,
    open_context: ?*anyopaque = null,
    open_callback: ?DataChannel.StateCallback = null,
    close_context: ?*anyopaque = null,
    close_callback: ?DataChannel.StateCallback = null,

    fn handle(self: *Channel) DataChannel {
        return .{ .ptr = self, .vtable = &channel_vtable };
    }
};

const peer_vtable: PeerConnection.VTable = .{
    .create_offer = createOffer,
    .create_answer = createAnswer,
    .set_local_description = setLocalDescription,
    .set_remote_description = setRemoteDescription,
    .get_local_description = getLocalDescription,
    .add_ice_candidate = addIceCandidate,
    .on_ice_candidate = registerIceCandidate,
    .on_state_change = registerStateChange,
    .on_data_channel = registerDataChannel,
    .close = closePeer,
    .create_data_channel = createDataChannelAdapter,
};

fn createOffer(ptr: *anyopaque) !Description {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    const description = try self.peer.createOffer();
    return .{ .type = .offer, .sdp = description.sdp };
}

fn createAnswer(ptr: *anyopaque) !Description {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    const description = try self.peer.createAnswer();
    return .{ .type = .answer, .sdp = description.sdp };
}

fn setLocalDescription(ptr: *anyopaque, description: Description) !void {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    try self.peer.setLocalDescription(.{
        .type = switch (description.type) {
            .offer => .offer,
            .answer => .answer,
        },
        .sdp = description.sdp,
    });
    try self.refreshLocalDescription();
}

fn setRemoteDescription(ptr: *anyopaque, description: Description) !void {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    try self.peer.setRemoteDescription(.{
        .type = switch (description.type) {
            .offer => .offer,
            .answer => .answer,
        },
        .sdp = description.sdp,
    });
}

fn getLocalDescription(ptr: *anyopaque) ?Description {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    if (self.local_sdp.len == 0) return null;
    return .{ .type = self.local_type, .sdp = self.local_sdp };
}

fn addIceCandidate(_: *anyopaque, _: []const u8) !void {}

fn createDataChannelAdapter(ptr: *anyopaque, label: []const u8, reliable: bool) !DataChannel {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    return self.createDataChannel(label, reliable);
}

fn registerIceCandidate(ptr: *anyopaque, context: ?*anyopaque, callback: PeerConnection.IceCandidateCallback) void {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    self.onIceCandidate(context, callback);
}

fn registerStateChange(ptr: *anyopaque, context: ?*anyopaque, callback: PeerConnection.StateCallback) void {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    self.onStateChange(context, callback);
}

fn registerDataChannel(ptr: *anyopaque, context: ?*anyopaque, callback: PeerConnection.DataChannelCallback) void {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    self.data_context = context;
    self.data_callback = callback;
}

fn closePeer(ptr: *anyopaque) void {
    const self: *Peer = @ptrCast(@alignCast(ptr));
    self.peer.close();
    self.deinit();
}

const handler_vtable: Handler.VTable = .{
    .onConnectionStateChange = handleConnectionState,
    .onIceCandidate = handleIceCandidate,
    .onDataChannel = handleDataChannel,
};

fn handleConnectionState(userdata: ?*anyopaque, state: webrtc.PeerConnection.ConnectionState) void {
    const self: *Peer = @ptrCast(@alignCast(userdata orelse return));
    if (self.state_callback) |callback| callback(self.state_context, switch (state) {
        .new => .new,
        .connecting => .connecting,
        .connected => .connected,
        .disconnected => .disconnected,
        .failed => .failed,
        .closed => .closed,
    });
}

fn handleIceCandidate(userdata: ?*anyopaque, candidate: ?IceCandidate) void {
    const self: *Peer = @ptrCast(@alignCast(userdata orelse return));
    const value = candidate orelse return;
    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    writer.print("{f}", .{value}) catch return;
    if (self.ice_callback) |callback| callback(self.ice_context, writer.buffered());
}

fn handleDataChannel(userdata: ?*anyopaque, channel: *webrtc.DataChannel) void {
    const self: *Peer = @ptrCast(@alignCast(userdata orelse return));
    const wrapped = self.wrapChannel(channel) catch return;
    if (self.data_callback) |callback| callback(self.data_context, wrapped);
}

const channel_vtable: DataChannel.VTable = .{
    .send = send,
    .close = closeChannel,
    .is_open = isOpen,
    .label = dataChannelLabel,
    .on_message = onMessage,
    .on_open = onOpen,
    .on_close = onClose,
};

fn handleDataEvent(userdata: ?*anyopaque, _: *webrtc.DataChannel, event: DataEvent) void {
    const self: *Channel = @ptrCast(@alignCast(userdata orelse return));
    switch (event) {
        .binary_message => |data| if (self.message_callback) |callback| callback(self.message_context, data),
        .open => if (self.open_callback) |callback| callback(self.open_context),
        .close => if (self.close_callback) |callback| callback(self.close_context),
        else => {},
    }
}

fn send(ptr: *anyopaque, data: []const u8) !void {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    try self.channel.sendBinary(data);
}

fn closeChannel(ptr: *anyopaque) void {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    self.channel.close() catch {};
}

fn isOpen(ptr: *anyopaque) bool {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    return self.channel.ready_state == .open;
}

fn dataChannelLabel(ptr: *anyopaque) []const u8 {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    return self.channel.label;
}

fn onMessage(ptr: *anyopaque, context: ?*anyopaque, callback: DataChannel.MessageCallback) void {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    self.message_context = context;
    self.message_callback = callback;
    self.channel.registerCallback(self, &handleDataEvent);
}

fn onOpen(ptr: *anyopaque, context: ?*anyopaque, callback: DataChannel.StateCallback) void {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    self.open_context = context;
    self.open_callback = callback;
    self.channel.registerCallback(self, &handleDataEvent);
}

fn onClose(ptr: *anyopaque, context: ?*anyopaque, callback: DataChannel.StateCallback) void {
    const self: *Channel = @ptrCast(@alignCast(ptr));
    self.close_context = context;
    self.close_callback = callback;
    self.channel.registerCallback(self, &handleDataEvent);
}

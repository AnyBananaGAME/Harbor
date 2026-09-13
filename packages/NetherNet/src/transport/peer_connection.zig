pub const DescriptionType = enum {
    offer,
    answer,
};

pub const Description = struct {
    type: DescriptionType,
    sdp: []const u8,
};

pub const State = enum {
    new,
    connecting,
    connected,
    disconnected,
    failed,
    closed,
};

pub const PeerConnection = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const IceCandidateCallback = *const fn (
        context: ?*anyopaque,
        candidate: []const u8,
    ) void;

    pub const StateCallback = *const fn (
        context: ?*anyopaque,
        state: State,
    ) void;

    pub const DataChannelCallback = *const fn (
        context: ?*anyopaque,
        channel: @import("channel.zig").DataChannel,
    ) void;

    pub const VTable = struct {
        create_offer: *const fn (
            ptr: *anyopaque,
        ) anyerror!Description,

        create_answer: *const fn (
            ptr: *anyopaque,
        ) anyerror!Description,

        set_local_description: *const fn (
            ptr: *anyopaque,
            description: Description,
        ) anyerror!void,

        set_remote_description: *const fn (
            ptr: *anyopaque,
            description: Description,
        ) anyerror!void,

        get_local_description: *const fn (
            ptr: *anyopaque,
        ) ?Description,

        add_ice_candidate: *const fn (
            ptr: *anyopaque,
            candidate: []const u8,
        ) anyerror!void,

        on_ice_candidate: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: IceCandidateCallback,
        ) void,

        on_state_change: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: StateCallback,
        ) void,

        on_data_channel: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: DataChannelCallback,
        ) void,

        close: *const fn (
            ptr: *anyopaque,
        ) void,

        create_data_channel: *const fn (
            ptr: *anyopaque,
            label: []const u8,
            reliable: bool,
        ) anyerror!@import("channel.zig").DataChannel,
    };

    /// Creates an SDP offer.
    pub fn createOffer(
        self: PeerConnection,
    ) !Description {
        return self.vtable.create_offer(self.ptr);
    }

    /// Creates an SDP answer.
    pub fn createAnswer(
        self: PeerConnection,
    ) !Description {
        return self.vtable.create_answer(self.ptr);
    }

    /// Sets the local SDP description.
    pub fn setLocalDescription(
        self: PeerConnection,
        description: Description,
    ) !void {
        try self.vtable.set_local_description(
            self.ptr,
            description,
        );
    }

    /// Sets the remote SDP description.
    pub fn setRemoteDescription(
        self: PeerConnection,
        description: Description,
    ) !void {
        try self.vtable.set_remote_description(
            self.ptr,
            description,
        );
    }

    pub fn localDescription(self: PeerConnection) ?Description {
        return self.vtable.get_local_description(self.ptr);
    }

    /// Adds a remote ICE candidate.
    pub fn addIceCandidate(
        self: PeerConnection,
        candidate: []const u8,
    ) !void {
        try self.vtable.add_ice_candidate(
            self.ptr,
            candidate,
        );
    }

    /// Registers a callback for local ICE candidates.
    pub fn onIceCandidate(
        self: PeerConnection,
        context: ?*anyopaque,
        callback: IceCandidateCallback,
    ) void {
        self.vtable.on_ice_candidate(
            self.ptr,
            context,
            callback,
        );
    }

    /// Registers a callback for peer connection state changes.
    pub fn onStateChange(
        self: PeerConnection,
        context: ?*anyopaque,
        callback: StateCallback,
    ) void {
        self.vtable.on_state_change(
            self.ptr,
            context,
            callback,
        );
    }

    /// Closes the peer connection.
    pub fn close(self: PeerConnection) void {
        self.vtable.close(self.ptr);
    }

    pub fn onDataChannel(
        self: PeerConnection,
        context: ?*anyopaque,
        callback: DataChannelCallback,
    ) void {
        self.vtable.on_data_channel(self.ptr, context, callback);
    }

    pub fn createDataChannel(
        self: PeerConnection,
        label: []const u8,
        reliable: bool,
    ) !@import("channel.zig").DataChannel {
        return self.vtable.create_data_channel(self.ptr, label, reliable);
    }
};

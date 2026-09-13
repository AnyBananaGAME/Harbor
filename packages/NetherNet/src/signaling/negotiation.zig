const PeerConnection = @import("../transport/peer_connection.zig").PeerConnection;
const Signal = @import("signal.zig").Signal;
const Signaler = @import("signaler.zig").Signaler;

pub const Role = enum {
    controlling,
    controlled,
};

pub const Negotiation = struct {
    peer: PeerConnection,
    signaler: Signaler,

    role: Role,
    connection_id: u64,
    remote_network_id: []const u8,

    pub fn init(
        peer: PeerConnection,
        signaler: Signaler,
        role: Role,
        connection_id: u64,
        remote_network_id: []const u8,
    ) Negotiation {
        return .{
            .peer = peer,
            .signaler = signaler,
            .role = role,
            .connection_id = connection_id,
            .remote_network_id = remote_network_id,
        };
    }

    pub fn handleSignal(
        self: *Negotiation,
        signal: Signal,
    ) !void {
        switch (signal.type) {
            .offer => {
                if (self.role != .controlled)
                    return error.UnexpectedOffer;

                try self.peer.setRemoteDescription(.{
                    .type = .offer,
                    .sdp = signal.data,
                });

                const answer = try self.peer.createAnswer();
                try self.peer.setLocalDescription(answer);
                try self.signaler.send(.{
                    .type = .answer,
                    .connection_id = self.connection_id,
                    .network_id = self.remote_network_id,
                    .data = (self.peer.localDescription() orelse answer).sdp,
                });
            },

            .answer => {
                if (self.role != .controlling)
                    return error.UnexpectedAnswer;

                try self.peer.setRemoteDescription(.{
                    .type = .answer,
                    .sdp = signal.data,
                });
            },

            .candidate => {
                try self.peer.addIceCandidate(
                    signal.data,
                );
            },

            .failure => {
                return error.RemoteNegotiationFailed;
            },
        }
    }
};

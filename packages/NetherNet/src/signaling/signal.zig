pub const SignalType = enum {
    offer,
    answer,
    candidate,
    failure,
};

pub const Signal = struct {
    type: SignalType,

    connection_id: u64,
    network_id: []const u8,

    data: []const u8,
};

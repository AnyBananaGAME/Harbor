const NetherNetChannel =
    @import("nethernet_channel.zig").NetherNetChannel;

pub const Connection = struct {
    reliable: NetherNetChannel,
    unreliable: ?NetherNetChannel,

    pub fn init(
        reliable: NetherNetChannel,
        unreliable: ?NetherNetChannel,
    ) Connection {
        return .{
            .reliable = reliable,
            .unreliable = unreliable,
        };
    }

    /// Sends a packet reliably.
    pub fn send(
        self: *Connection,
        data: []const u8,
    ) !void {
        try self.reliable.send(data);
    }

    /// Sends a packet using the **UNRELIABLE** channel.
    pub fn sendUnreliable(
        self: *Connection,
        data: []const u8,
    ) !void {
        if (self.unreliable) |*channel| {
            try channel.send(data);
            return;
        }

        return error.UnreliableChannelUnavailable;
    }

    /// Returns true when the **RELIABLE** channel is open.
    pub fn isOpen(self: *const Connection) bool {
        return self.reliable.channel.isOpen();
    }

    pub fn close(self: *Connection) void {
        self.reliable.channel.close();

        if (self.unreliable) |*channel| {
            channel.channel.close();
        }
    }
};

const RequestNetworkSettingsPacket = @import("request-network-settings.zig");

pub const Packet = union(enum) {
    request_network_settings: RequestNetworkSettingsPacket,
};

pub const PacketPool = struct {
    // There are more than 128 packets in mcbe but for now 128 works fine and i doubt all of em will be implemented any time soon
    slots: [128]?Packet = [_]?Packet{null} ** 128,

    pub fn get(self: *@This(), id: u32) !*Packet {
        for (&self.slots) |*slot| {
            if (slot.* == null) {
                slot.* = switch (id) {
                    RequestNetworkSettingsPacket.ID => .{
                        .request_network_settings = undefined,
                    },
                    else => return error.UnknownPacketId,
                };
                return &slot.*.?;
            }
        }
        return error.PacketPoolFull;
    }

    pub fn release(self: *@This(), packet: *Packet) void {
        for (&self.slots) |*slot| {
            if (slot.*) |*value| {
                if (value == packet) {
                    slot.* = null;
                    return;
                }
            }
        }
    }
};

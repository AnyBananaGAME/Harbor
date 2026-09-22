const Protocol = @import("Protocol");
const ActorFlag = Protocol.Enums.ActorFlag;

pub const ActorFlags = struct {
    flags: u128 = 0,

    pub fn init() ActorFlags {
        return .{};
    }

    pub fn flag(self: ActorFlags, f: ActorFlag) bool {
        const shift: u7 = @intCast(@intFromEnum(f));
        return ((self.flags >> shift) & 1) != 0;
    }

    pub fn setFlag(self: *ActorFlags, f: ActorFlag, value: bool) void {
        const shift: u7 = @intCast(@intFromEnum(f));
        const mask: u128 = @as(u128, 1) << shift;

        if (value) {
            self.flags |= mask;
        } else {
            self.flags &= ~mask;
        }
    }
};

// Player is technically an entity, so it iwll also need to hold entity
// inside of it, so once entity is implemented maybe usinga VTable
// i'd have to implement it here

const Protocol = @import("Protocol");
const LoginPayload = Protocol.LoginFlow.LoginPayload;
const Session = @import("NetherNet").Session;

pub const Player = struct {
    session: *Session,
    login: LoginPayload,

    pub fn init(session: *Session, login: LoginPayload) Player {
        return .{ .session = session, .login = login };
    }

    pub fn deinit(self: *Player) void {
        self.login.deinit();
    }

    pub fn getUsername(self: *const Player) []const u8 {
        return self.login.identity.xname;
    }

    pub fn getXuid(self: *const Player) []const u8 {
        return self.login.identity.xid;
    }
};

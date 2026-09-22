// Player is technically an entity, so it iwll also need to hold entity
// inside of it, so once entity is implemented maybe usinga VTable
// i'd have to implement it here

const Protocol = @import("Protocol");
const LoginPayload = Protocol.LoginFlow.LoginPayload;
const Session = @import("NetherNet").Session;
const ChunkViewer = @import("chunk-viewer.zig").PlayerChunkView;
const Entity = @import("../entity/entity.zig").Entity;

pub const Player = struct {
    /// Nethernet session of the player.
    session: *Session,

    /// Login payload of the player that is sent in login packet
    login: LoginPayload,

    /// Chunk viewer of the player.
    chunk_viewer: ChunkViewer,

    /// The actor of the player.
    actor: Entity,

    pub fn init(session: *Session, login: LoginPayload) Player {
        var player = Player{
            .session = session,
            .login = login,
            .chunk_viewer = ChunkViewer{},
            .actor = Entity.init("minecraft:player"),
        };

        player.actor.flags.setFlag(.AlwaysShowName, true);
        player.actor.flags.setFlag(.Breathing, true);
        player.actor.flags.setFlag(.HasGravity, true);

        return player;
    }

    pub fn deinit(self: *Player) void {
        self.login.deinit();
    }

    /// Returns the username of the player.
    pub fn getUsername(self: *const Player) []const u8 {
        return self.login.identity.xname;
    }

    /// Returns the xuid of the player.
    pub fn getXuid(self: *const Player) []const u8 {
        return self.login.identity.xid;
    }

    /// Returns the unique id of the player.
    pub fn getUniqueId(self: *const Player) i64 {
        return self.actor.unique_id;
    }

    /// Returns the runtime id of the player.
    pub fn getRuntimeId(self: *const Player) u64 {
        return self.actor.runtime_id;
    }
};

const ActorFlags = @import("./metadata/flags.zig").ActorFlags;
const ActorId = @import("./metadata/actor-id.zig");

pub const Entity = struct {
    /// The unique id of the entity.
    unique_id: i64,

    /// The runtime id of the entity
    runtime_id: u64,

    /// The flags of the entity.
    flags: ActorFlags,

    pub fn init() Entity {
        return .{
            .unique_id = ActorId.nextUniqueId(),
            .runtime_id = ActorId.nextRuntimeId(),
            .flags = ActorFlags.init(),
        };
    }
};

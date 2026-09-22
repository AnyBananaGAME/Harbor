const std = @import("std");
const Protocol = @import("Protocol");

const ActorFlags = @import("./metadata/flags.zig").ActorFlags;
const ActorId = @import("./metadata/actor-id.zig");
const ActorDataId = Protocol.Enums.ActorDataId;
const Dimension = @import("../world/dimension.zig").Dimension;
const ActorAttributes = @import("./metadata/attributes.zig").ActorAttributes;
const EntityIdentifier = Protocol.Enums.EntityIdentifier;

pub const Entity = struct {
    /// The unique id of the entity.
    unique_id: i64,

    /// The runtime id of the entity
    runtime_id: u64,

    /// The identifier of the entity.
    identifier: []const u8,

    /// The flags of the entity.
    flags: ActorFlags,

    /// The entity position.
    position: Protocol.Types.Vec3,

    /// The dimension containing the entity.
    dimension: *Dimension,

    /// The attributes of the entity.
    attributes: ActorAttributes,

    pub fn init(
        dimension: *Dimension,
        identifier: []const u8,
    ) Entity {
        return .{
            .unique_id = ActorId.nextUniqueId(),
            .runtime_id = ActorId.nextRuntimeId(),
            .flags = ActorFlags.init(),
            .identifier = identifier,
            .position = .{},
            .dimension = dimension,
            .attributes = ActorAttributes.init(),
        };
    }

    pub fn onSpawn(self: *Entity) !void {
        self.flags.setFlag(.Breathing, true);
        self.flags.setFlag(.HasGravity, true);

        var packet = Protocol.Packets.SetActorDataPacket{
            .actor_runtime_id = self.runtime_id,
            .tick = 0,
        };
        packet.actor_data_count = 2;
        packet.actor_data[0] = .{
            .id = @intFromEnum(ActorDataId.Flags),
            .value = .{ .Int64 = @bitCast(@as(u64, @truncate(self.flags.flags))) },
        };
        packet.actor_data[1] = .{
            .id = @intFromEnum(ActorDataId.FlagsUpper),
            .value = .{ .Int64 = @bitCast(@as(u64, @truncate(self.flags.flags >> 64))) },
        };

        var buffer: [4096]u8 = undefined;
        var stream = @import("BinaryStream").BinaryStream.init(&buffer, 0);
        const payload = try packet.serialize(&stream);
        try self.dimension.broadcast(
            self.position,
            Protocol.Packets.SetActorDataPacket.ID,
            payload,
            .{},
        );

        if (std.mem.eql(u8, self.identifier, EntityIdentifier.Player.toString())) {
            self.attributes.set(.Movement, 0, 3.4028235e+38, 0.1, 0.1);
            self.attributes.set(.UnderwaterMovement, 0, 3.4028235e+38, 0.02, 0.02);
            self.attributes.set(.LavaMovement, 0, 3.4028235e+38, 0.02, 0.02);
        }

        try self.attributes.broadcast(self);
    }
};

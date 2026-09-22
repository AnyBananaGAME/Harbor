const std = @import("std");
const Protocol = @import("Protocol");
const BinaryStream = @import("BinaryStream").BinaryStream;
const AttributeName = Protocol.Enums.AttributeName;
const AttributeData = Protocol.Types.AttributeData;
const Dimension = @import("../../world/dimension.zig").Dimension;
const Entity = @import("../entity.zig").Entity;

pub const ActorAttributes = struct {
    attributes: std.EnumArray(AttributeName, ?AttributeData),

    /// Initialize an empty ActorAttributes struct.
    pub fn init() ActorAttributes {
        return .{
            .attributes = .initFill(null),
        };
    }

    /// Set an attribute value for the given name.
    pub fn set(
        self: *ActorAttributes,
        name: AttributeName,
        min: f32,
        max: f32,
        current: f32,
        default: f32,
    ) void {
        self.attributes.set(name, AttributeData{
            .name = name.toString(),
            .minimum = min,
            .maximum = max,
            .current = current,
            .default_value = default,
            .default_maximum = max,
            .default_minimum = min,
            .modifiers_count = 0,
        });
    }

    /// Get the attribute data for the given name.
    pub fn get(self: *const ActorAttributes, name: AttributeName) ?AttributeData {
        return self.attributes.get(name);
    }

    /// Get the current value of the attribute for the given name.
    pub fn getCurrent(self: *const ActorAttributes, name: AttributeName) ?f32 {
        if (self.get(name)) |attr| {
            return attr.current;
        }
        return null;
    }

    /// Set the current value of the attribute for the given name.
    pub fn setCurrent(self: *ActorAttributes, name: AttributeName, value: f32) void {
        const attr_ptr = self.attributes.getPtr(name);
        if (attr_ptr.*) |*attr| {
            attr.current = value;
        }
    }

    pub fn broadcast(
        self: *const ActorAttributes,
        entity: *Entity,
    ) !void {
        const names = std.enums.values(AttributeName);
        var buf: [names.len]AttributeData = undefined;
        var count: usize = 0;
        for (names) |name| {
            if (self.get(name)) |attr| {
                buf[count] = attr;
                count += 1;
            }
        }

        var buffer: [4096]u8 = undefined;
        var stream = BinaryStream.init(&buffer, 0);
        var packet = Protocol.Packets.UpdateAttributesPacket{
            .actor_runtime_id = entity.runtime_id,
            .tick = 0,
        };
        packet.attribute_count = count;

        @memcpy(packet.attributes[0..count], buf[0..count]);
        const payload = try packet.serialize(&stream);

        try entity.dimension.broadcast(
            entity.position,
            Protocol.Packets.UpdateAttributesPacket.ID,
            payload,
            .{},
        );
    }

    // TODO: Attribute modifiers
    //
    //
};

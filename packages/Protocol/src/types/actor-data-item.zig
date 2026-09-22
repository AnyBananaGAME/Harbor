const BinaryStream = @import("binarystream").BinaryStream;
const Nbt = @import("Nbt");
const ActorDataType = @import("../enums/actor-data-type.zig").ActorDataType;
const BlockPos = @import("./block-pos.zig").BlockPos;
const Vec3 = @import("./vec3.zig").Vec3;

pub const ActorDataItem = struct {
    id: u32 = 0,
    value: Value = .{ .Byte = 0 },

    pub const Value = union(ActorDataType) {
        Byte: i8,
        Short: i16,
        Int: i32,
        Float: f32,
        String: []const u8,
        CompoundTag: Nbt.Tag,
        Pos: BlockPos,
        Int64: i64,
        Vec3: Vec3,
    };

    pub fn read(stream: *BinaryStream) !@This() {
        const id = try stream.readVarUint32();
        const raw_type = try stream.readVarUint32();
        const legacy_type = try stream.readU8();
        if (raw_type != legacy_type) return error.ActorDataTypeMismatch;
        if (legacy_type > @intFromEnum(ActorDataType.Vec3))
            return error.InvalidActorDataType;
        const data_type: ActorDataType = @enumFromInt(legacy_type);

        const value: Value = switch (data_type) {
            .Byte => .{ .Byte = try stream.readI8() },
            .Short => .{ .Short = try stream.readI16(.little) },
            .Int => .{ .Int = try stream.readZigZag() },
            .Float => .{ .Float = try stream.readF32(.little) },
            .String => .{ .String = try stream.readVarString() },
            .CompoundTag => .{ .CompoundTag = try Nbt.Tag.deserialize(stream, .network) },
            .Pos => .{ .Pos = try BlockPos.read(stream) },
            .Int64 => .{ .Int64 = try stream.readVarInt64() },
            .Vec3 => .{ .Vec3 = try Vec3.read(stream) },
        };

        return .{ .id = id, .value = value };
    }

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        const data_type = @as(ActorDataType, self.value);
        try stream.writeVarUint32(self.id);
        try stream.writeVarUint32(@intFromEnum(data_type));
        try stream.writeU8(@intFromEnum(data_type));

        switch (self.value) {
            .Byte => |value| try stream.writeI8(value),
            .Short => |value| try stream.writeI16(value, .little),
            .Int => |value| try stream.writeVarInt32(value),
            .Float => |value| try stream.writeF32(value, .little),
            .String => |value| try stream.writeVarString(value),
            .CompoundTag => |value| {
                var tag = value;
                try tag.serialize(stream, .network);
            },
            .Pos => |value| try value.write(stream),
            .Int64 => |value| try stream.writeVarInt64(value),
            .Vec3 => |value| try value.write(stream),
        }
    }
};

const BinaryStream = @import("binarystream").BinaryStream;
const ActorDataItem = @import("../types/actor-data-item.zig").ActorDataItem;
const IntEntry = @import("../types/property-sync.zig").IntEntry;
const FloatEntry = @import("../types/property-sync.zig").FloatEntry;

pub const ID: u32 = 39;

const Self = @This();
pub const MaxActorData = 64;
pub const MaxPropertyEntries = 64;

actor_runtime_id: u64,
actor_data: [MaxActorData]ActorDataItem = undefined,
actor_data_count: usize = 0,
synched_int_entries: [MaxPropertyEntries]IntEntry = undefined,
synched_int_count: usize = 0,
synched_float_entries: [MaxPropertyEntries]FloatEntry = undefined,
synched_float_count: usize = 0,
tick: u64,

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeVarUint64(self.actor_runtime_id);
    try stream.writeVarUint32(@intCast(self.actor_data_count));
    for (self.actor_data[0..self.actor_data_count]) |*item| try item.write(stream);
    try stream.writeVarUint32(@intCast(self.synched_int_count));
    for (self.synched_int_entries[0..self.synched_int_count]) |entry| {
        try stream.writeVarUint32(entry.property_index);
        try stream.writeVarInt32(entry.data);
    }
    try stream.writeVarUint32(@intCast(self.synched_float_count));
    for (self.synched_float_entries[0..self.synched_float_count]) |entry| {
        try stream.writeVarUint32(entry.property_index);
        try stream.writeF32(entry.data, .little);
    }
    try stream.writeVarUint64(self.tick);
    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream) !Self {
    var self: Self = .{
        .actor_runtime_id = try stream.readVarUint64(),
        .tick = undefined,
    };

    self.actor_data_count = try stream.readVarUint32();
    if (self.actor_data_count > MaxActorData) return error.TooManyActorData;
    for (self.actor_data[0..self.actor_data_count]) |*item|
        item.* = try ActorDataItem.read(stream);

    self.synched_int_count = try stream.readVarUint32();
    if (self.synched_int_count > MaxPropertyEntries)
        return error.TooManyPropertyEntries;
    for (self.synched_int_entries[0..self.synched_int_count]) |*entry|
        entry.* = try IntEntry.read(stream);

    self.synched_float_count = try stream.readVarUint32();
    if (self.synched_float_count > MaxPropertyEntries)
        return error.TooManyPropertyEntries;
    for (self.synched_float_entries[0..self.synched_float_count]) |*entry|
        entry.* = try FloatEntry.read(stream);

    self.tick = try stream.readVarUint64();
    return self;
}

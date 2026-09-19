const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ResourcePackResponse = @import("../enums/resource-pack-response.zig").ResourcePackResponse;
const Self = @This();

pub const ID: u32 = 8;

response: ResourcePackResponse = .Cancel,
downloading_packs: []const []const u8 = &.{},

pub fn serialize(self: *Self, stream: *BinaryStream) ![]const u8 {
    try stream.writeI8(@intFromEnum(self.response) - 1);
    try stream.writeVarString(@tagName(self.response));

    if (self.response == .Downloading) {
        try stream.writeVarUint32(@intCast(self.downloading_packs.len));
        for (self.downloading_packs) |pack| try stream.writeVarString(pack);
    }

    return stream.getBuffer();
}

pub fn deserialize(stream: *BinaryStream, allocator: std.mem.Allocator) !Self {
    const response: ResourcePackResponse = @enumFromInt(try stream.readI8() + 1);
    _ = try stream.readVarString();

    if (response != .Downloading) return .{ .response = response };

    const packs = try allocator.alloc([]const u8, try stream.readVarUint32());
    for (packs) |*pack| pack.* = try stream.readVarString();

    return .{ .response = response, .downloading_packs = packs };
}

const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;

const Self = @This();

// Identity holds the Token provided by Xbox Live/Minecraft Services
identity: []const u8,

// Client holds payloads provided by the client
client: []const u8,

pub fn read(stream: *BinaryStream) !Self {
    const request = try stream.readVarString();
    var requestStream = BinaryStream.init(request, 0);

    return Self{
        .identity = try requestStream.readString32(.little),
        .client = try requestStream.readString32(.little),
    };
}

pub fn write(self: *const Self, stream: *BinaryStream) !void {
    const requestLength = 4 + self.identity.len + 4 + self.client.len;

    if (requestLength > std.math.maxInt(u32)) {
        return error.StringTooLong;
    }

    try stream.writeVarUint32(@intCast(requestLength));
    try stream.writeString32(self.identity, .little);
    try stream.writeString32(self.client, .little);
}

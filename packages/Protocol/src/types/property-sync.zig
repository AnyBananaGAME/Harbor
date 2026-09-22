const BinaryStream = @import("binarystream").BinaryStream;

pub const IntEntry = struct {
    property_index: u32 = 0,
    data: i32 = 0,

    pub fn read(stream: *BinaryStream) !@This() {
        return .{ .property_index = try stream.readVarUint32(), .data = try stream.readZigZag() };
    }
};

pub const FloatEntry = struct {
    property_index: u32 = 0,
    data: f32 = 0,

    pub fn read(stream: *BinaryStream) !@This() {
        return .{ .property_index = try stream.readVarUint32(), .data = try stream.readF32(.little) };
    }
};

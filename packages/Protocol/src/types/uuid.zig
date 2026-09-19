const BinaryStream = @import("binarystream").BinaryStream;

pub const Uuid = struct {
    most_significant_bits: u64 = 0,
    least_significant_bits: u64 = 0,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeU64(self.most_significant_bits, .little);
        try stream.writeU64(self.least_significant_bits, .little);
    }
};

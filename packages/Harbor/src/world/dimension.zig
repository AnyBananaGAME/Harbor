const std = @import("std");
const Protocol = @import("Protocol");
const DimensionType = Protocol.Enums.DimensionType;

pub const Dimension = struct {
    /// allocator used in the dimension.
    allocator: std.mem.Allocator,

    /// The identifier of the dimension. aka a name
    identifier: []const u8,

    /// The type of the world. e.g. Overworld, Nether, TheEnd.
    typ: DimensionType,

    /// Initialize a new dimension.
    pub fn init(allocator: std.mem.Allocator, identifier: []const u8, typ: DimensionType) !Dimension {
        return .{
            .allocator = allocator,
            .identifier = identifier,
            .typ = typ,
        };
    }
};

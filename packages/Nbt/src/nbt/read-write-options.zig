const std = @import("std");

pub const ReadWriteOptions = struct {
    name: bool = true,
    tag_type: bool = true,
    varint: bool = false,
    endian: std.builtin.Endian = .little,

    pub const default: ReadWriteOptions = .{
        .name = true,
        .tag_type = true,
        .varint = false,
        .endian = .little,
    };

    pub const no_name: ReadWriteOptions = .{
        .name = false,
        .tag_type = true,
        .varint = false,
        .endian = .little,
    };

    pub const no_type: ReadWriteOptions = .{
        .name = true,
        .tag_type = false,
        .varint = false,
        .endian = .little,
    };

    pub const network: ReadWriteOptions = .{
        .name = true,
        .tag_type = true,
        .varint = true,
        .endian = .little,
    };

    pub const big_endian: ReadWriteOptions = .{
        .name = true,
        .tag_type = true,
        .varint = false,
        .endian = .big,
    };
};

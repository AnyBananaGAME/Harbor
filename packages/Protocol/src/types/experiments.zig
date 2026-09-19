const std = @import("std");
const BinaryStream = @import("binarystream").BinaryStream;
const ExperimentToggle = @import("experiment-toggle.zig").ExperimentToggle;

pub const Experiments = struct {
    toggles: []ExperimentToggle = &.{},
    experiments_ever_toggled: bool = false,

    pub fn write(self: *const @This(), stream: *BinaryStream) !void {
        try stream.writeU32(@intCast(self.toggles.len), .little);
        for (self.toggles) |*toggle| try toggle.write(stream);
        try stream.writeBool(self.experiments_ever_toggled);
    }

    pub fn read(stream: *BinaryStream, allocator: std.mem.Allocator) !@This() {
        const toggles = try allocator.alloc(ExperimentToggle, try stream.readU32(.little));
        for (toggles) |*toggle| toggle.* = try ExperimentToggle.read(stream);
        return .{ .toggles = toggles, .experiments_ever_toggled = try stream.readBool() };
    }
};

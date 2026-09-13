const std = @import("std");

/// A message assembler that can be used to assemble messages from multiple segments.
pub fn MessageAssembler(comptime capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [capacity]u8 = undefined,
        len: usize = 0,
        current_segment_count: ?u8 = null,

        /// Reset the assembler.
        pub fn reset(self: *Self) void {
            self.len = 0;
            self.current_segment_count = null;
        }

        pub fn push(
            self: *Self,
            data: []const u8,
        ) !?[]const u8 {
            if (data.len < 2)
                return error.InvalidSegment;

            const segment = data[0];
            const payload = data[1..];

            if (self.current_segment_count) |current| {
                if (current == 0 or segment != current - 1) {
                    self.reset();
                    return error.InvalidSegmentOrder;
                }
            }

            if (self.len + payload.len > self.buffer.len) {
                self.reset();
                return error.MessageTooLarge;
            }

            @memcpy(
                self.buffer[self.len .. self.len + payload.len],
                payload,
            );

            self.len += payload.len;
            self.current_segment_count = segment;

            if (segment != 0)
                return null;

            const result = self.buffer[0..self.len];
            return result;
        }
    };
}

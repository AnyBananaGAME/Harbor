const std = @import("std");
const Session = @import("session.zig").Session;

pub const BlockSize = 64;

const Block = struct {
    slots: [BlockSize]?Session = [_]?Session{null} ** BlockSize,
    next: ?*Block = null,
};

pub const Pool = struct {
    allocator: std.mem.Allocator,
    first: ?*Block = null,

    pub fn init(allocator: std.mem.Allocator) Pool {
        return .{ .allocator = allocator };
    }

    pub fn acquire(self: *Pool) !*?Session {
        var block = self.first;
        while (block) |current| : (block = current.next) {
            for (&current.slots) |*slot| {
                if (slot.* == null) return slot;
            }
        }

        const new_block = try self.allocator.create(Block);
        new_block.* = .{};
        new_block.next = self.first;
        self.first = new_block;
        return &new_block.slots[0];
    }

    pub fn release(self: *Pool, session: *Session) void {
        _ = self;
        if (session.pool_slot) |slot| slot.* = null;
    }
};

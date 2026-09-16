const std = @import("std");
const NetherNet = @import("NetherNet");
const Player = @import("player.zig").Player;

pub const PlayerMap = struct {
    allocator: std.mem.Allocator,
    by_session: std.AutoHashMapUnmanaged(*NetherNet.Session, *Player) = .empty,
    by_xuid: std.StringHashMapUnmanaged(*Player) = .empty,
    by_username: std.StringHashMapUnmanaged(*Player) = .empty,
    next_entity_runtime_id: u64 = 1,
    next_entity_unique_id: i64 = 1,

    pub fn init(allocator: std.mem.Allocator) PlayerMap {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *PlayerMap) void {
        var iterator = self.by_session.valueIterator();
        while (iterator.next()) |player| {
            player.*.deinit();
            self.allocator.destroy(player.*);
        }

        self.by_session.deinit(self.allocator);
        self.by_xuid.deinit(self.allocator);
        self.by_username.deinit(self.allocator);
    }

    pub fn get(self: *PlayerMap, session: *NetherNet.Session) ?*Player {
        return self.by_session.get(session);
    }

    pub fn getByXuid(self: *PlayerMap, xuid: []const u8) ?*Player {
        return self.by_xuid.get(xuid);
    }

    pub fn getByUsername(self: *PlayerMap, username: []const u8) ?*Player {
        return self.by_username.get(username);
    }

    pub fn put(self: *PlayerMap, player: Player) !void {
        if (self.by_session.contains(player.session) or
            self.by_xuid.contains(player.getXuid()) or
            self.by_username.contains(player.getUsername())) return error.PlayerAlreadyExists;

        const stored = try self.allocator.create(Player);
        errdefer self.allocator.destroy(stored);
        stored.* = player;

        try self.by_session.put(self.allocator, stored.session, stored);
        errdefer _ = self.by_session.remove(stored.session);
        try self.by_xuid.put(self.allocator, stored.getXuid(), stored);
        errdefer _ = self.by_xuid.remove(stored.getXuid());
        try self.by_username.put(self.allocator, stored.getUsername(), stored);
    }

    pub fn remove(self: *PlayerMap, session: *NetherNet.Session) void {
        const player = self.by_session.get(session) orelse return;
        _ = self.by_xuid.remove(player.getXuid());
        _ = self.by_username.remove(player.getUsername());
        _ = self.by_session.remove(session);
        player.deinit();
        self.allocator.destroy(player);
    }
};

pub const Packets = @import("./packets/root.zig");
pub const Enums = @import("./enums/root.zig");
pub const Types = @import("./types/root.zig");
pub const LoginFlow = @import("./login/root.zig");

pub const CONSTANTS = struct {
    pub const ProtocolVersion: u32 = 2193;
    pub const MinecraftVersion: []const u8 = "26.50";
};

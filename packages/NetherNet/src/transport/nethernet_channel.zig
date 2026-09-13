const DataChannel = @import("channel.zig").DataChannel;
const MessageAssembler = @import("assembler.zig").MessageAssembler;

const Assembler = MessageAssembler(256 * 1024);
const MaxMessageSize = 16 * 1024;
const MaxPayloadSize = MaxMessageSize - 1;
const MaxPacketSize = 256 * 1024;

pub const NetherNetChannel = struct {
    channel: DataChannel,
    assembler: Assembler,

    packet_context: ?*anyopaque = null,
    /// Registers a callback to be called when a packet is received on the data channel.
    /// ```zig
    ///  const PacketCallback = *const fn (
    ///      context: ?*anyopaque,
    ///      data: []const u8,
    ///  ) void
    /// ```
    packet_callback: ?PacketCallback = null,

    pub const PacketCallback = *const fn (
        context: ?*anyopaque,
        data: []const u8,
    ) void;

    pub fn init(channel: DataChannel) NetherNetChannel {
        return .{
            .channel = channel,
            .assembler = .{},
        };
    }

    pub fn send(self: *NetherNetChannel, data: []const u8) !void {
        if (data.len == 0)
            return;

        if (data.len > MaxPacketSize)
            return error.MessageTooLarge;

        const segment_count = (data.len + MaxPayloadSize - 1) / MaxPayloadSize;
        if (segment_count > 256)
            return error.MessageTooLarge;

        var segment: [MaxMessageSize]u8 = undefined;
        var offset: usize = 0;

        while (offset < data.len) {
            const remaining = data.len - offset;
            const payload_len = @min(remaining, MaxPayloadSize);
            const segment_index = offset / MaxPayloadSize;

            segment[0] = @intCast(segment_count - segment_index - 1);
            @memcpy(segment[1 .. payload_len + 1], data[offset .. offset + payload_len]);
            try self.channel.send(segment[0 .. payload_len + 1]);

            offset += payload_len;
        }
    }

    pub fn onPacket(
        self: *NetherNetChannel,
        context: ?*anyopaque,
        callback: PacketCallback,
    ) void {
        self.packet_context = context;
        self.packet_callback = callback;
        self.channel.onMessage(self, handleMessage);
    }

    pub fn onOpen(
        self: *NetherNetChannel,
        context: ?*anyopaque,
        callback: DataChannel.StateCallback,
    ) void {
        self.channel.onOpen(context, callback);
    }

    pub fn onClose(
        self: *NetherNetChannel,
        context: ?*anyopaque,
        callback: DataChannel.StateCallback,
    ) void {
        self.channel.onClose(context, callback);
    }

    fn handleMessage(context: ?*anyopaque, data: []const u8) void {
        const self: *NetherNetChannel = @ptrCast(@alignCast(context.?));
        const packet = self.assembler.push(data) catch {
            self.assembler.reset();
            self.channel.close();
            return;
        } orelse return;

        if (self.packet_callback) |callback| {
            callback(self.packet_context, packet);
        }
    }
};

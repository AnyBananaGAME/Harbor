const std = @import("std");
const native = @import("native/libdatachannel.zig");
const Http = @import("signaling/http.zig");
const session_module = @import("session.zig");
const log = std.log.scoped(.nethernet_server);

pub const Handler = session_module.Handler;
pub const Session = session_module.Session;

pub const Server = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    bind_address: [:0]const u8,
    port: u16,
    handler: Handler,
    sessions: [32]?Session = [_]?Session{null} ** 32,

    pub fn init(io: std.Io, allocator: std.mem.Allocator, bind_address: [:0]const u8, port: u16, handler: Handler) Server {
        return .{
            .io = io,
            .allocator = allocator,
            .bind_address = bind_address,
            .port = port,
            .handler = handler,
        };
    }

    pub fn startHttp(self: *Server, http_address: std.Io.net.IpAddress) !void {
        var http = try Http.Server.init(.{
            .io = self.io,
            .allocator = self.allocator,
            .address = http_address,
            .answer = answerCallback,
            .user_data = self,
        });
        defer http.deinit();
        try http.run();
    }

    pub fn start(self: *Server, http_address: [:0]const u8, certificate_path: [:0]const u8, key_path: [:0]const u8, identity_key_path: [:0]const u8) !void {
        if (native.nethernet_https_start(
            http_address.ptr,
            self.port,
            certificate_path.ptr,
            key_path.ptr,
            identity_key_path.ptr,
            nativeAnswer,
            self,
        ) != 0) return error.SignalingStartFailed;
        while (true) self.io.sleep(.fromSeconds(60), .awake) catch return;
    }

    pub fn answer(self: *Server, offer: []const u8, buffer: []u8) ![]u8 {
        for (&self.sessions) |*slot| {
            if (slot.* != null) continue;
            var cleaned_offer: [64 * 1024 + 1]u8 = undefined;
            var cleaned_length: usize = 0;
            var line_start: usize = 0;

            while (line_start < offer.len) {
                const line_end =
                    std.mem.indexOfScalarPos(u8, offer, line_start, '\n') orelse offer.len;
                const line_end_without_cr =
                    if (line_end > line_start and offer[line_end - 1] == '\r')
                        line_end - 1
                    else
                        line_end;
                const line = offer[line_start..line_end_without_cr];

                if (!std.mem.startsWith(u8, line, "a=identity:")) {
                    const segment_end = if (line_end < offer.len) line_end + 1 else line_end;
                    const segment_length = segment_end - line_start;
                    if (cleaned_length + segment_length >= cleaned_offer.len)
                        return error.RequestTooLarge;

                    @memcpy(
                        cleaned_offer[cleaned_length .. cleaned_length + segment_length],
                        offer[line_start..segment_end],
                    );
                    cleaned_length += segment_length;
                }

                line_start = if (line_end < offer.len) line_end + 1 else offer.len;
            }

            cleaned_offer[cleaned_length] = 0;
            slot.* = .{
                .connection = try native.Connection.init("0.0.0.0", 0),
                .handler = self.handler,
            };
            const session = &slot.*.?;
            session.callback_state = session.callbacks();
            try session.connection.setCallbacks(&session.callback_state);
            try session.connection.setOffer(cleaned_offer[0..cleaned_length :0]);
            const answer_sdp = try session.connection.createAnswer(buffer);
            return answer_sdp;
        }
        log.warn("join rejected: session table is full", .{});
        return error.TooManyConnections;
    }
};

pub fn answerCallback(offer: []const u8, buffer: []u8, user_data: ?*anyopaque) ![]const u8 {
    const server: *Server = @ptrCast(@alignCast(user_data.?));
    return server.answer(offer, buffer);
}

fn nativeAnswer(offer: [*:0]const u8, offer_size: c_int, buffer: [*]u8, buffer_size: c_int, user_data: ?*anyopaque) callconv(.c) c_int {
    if (offer_size < 0 or buffer_size < 0) return -1;
    const server: *Server = @ptrCast(@alignCast(user_data.?));
    const result = server.answer(std.mem.span(offer)[0..@intCast(offer_size)], buffer[0..@intCast(buffer_size)]) catch return -1;
    return @intCast(result.len);
}

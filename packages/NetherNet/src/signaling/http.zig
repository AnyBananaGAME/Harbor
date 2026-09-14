const std = @import("std");
const signaling = @import("signaling.zig");

const log = std.log.scoped(.nethernet_http);

pub const AnswerFn = *const fn (offer: []const u8, answer: []u8, user_data: ?*anyopaque) anyerror![]const u8;

pub const Config = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    address: std.Io.net.IpAddress,
    answer: AnswerFn,
    user_data: ?*anyopaque = null,
};

pub const Server = struct {
    config: Config,
    listener: std.Io.net.Server,

    pub fn init(config: Config) !Server {
        return .{ .config = config, .listener = try config.address.listen(config.io, .{ .mode = .stream, .reuse_address = true }) };
    }

    pub fn deinit(self: *Server) void {
        self.listener.deinit(self.config.io);
    }

    pub fn run(self: *Server) !void {
        log.info("NetherNet HTTP signaling listening on {any}", .{self.config.address});
        while (self.listener.accept(self.config.io)) |stream| {
            self.handle(stream) catch |err| log.warn("HTTP signaling request failed: {s}", .{@errorName(err)});
        } else |err| return err;
    }

    fn handle(self: *Server, stream: std.Io.net.Stream) !void {
        defer stream.close(self.config.io);
        var input: [64 * 1024]u8 = undefined;
        var output: [70 * 1024]u8 = undefined;
        var reader = stream.reader(self.config.io, &input);
        var writer = stream.writer(self.config.io, &output);
        var http = std.http.Server.init(&reader.interface, &writer.interface);
        var request = try http.receiveHead();
        const parsed = signaling.parse(@tagName(request.head.method), request.head.target) catch {
            try request.respond("", .{ .status = .not_found });
            return;
        };
        if (parsed.kind == .capability) {
            try request.respond("", .{ .status = .no_content });
            return;
        }
        if (!signaling.acceptsSdp(request.head.content_type orelse "")) {
            try request.respond("", .{ .status = .unsupported_media_type });
            return;
        }
        const length = request.head.content_length orelse return error.ContentLengthRequired;
        if (length > input.len) return error.RequestTooLarge;
        const offer = input[0..length];
        var body_reader = request.readerExpectNone(&.{});
        try body_reader.readSliceAll(offer);
        var answer: [64 * 1024]u8 = undefined;
        const body = try self.config.answer(offer, &answer, self.config.user_data);
        try request.respond(body, .{ .status = .ok, .extra_headers = &.{.{ .name = "Content-Type", .value = "application/sdp" }} });
    }
};

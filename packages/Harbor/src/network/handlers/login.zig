const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Protocol = @import("Protocol");
const NetherNet = @import("NetherNet");
const Player = @import("../../player/player.zig").Player;

const NetworkManager = @import("../manager.zig").NetworkManager;

const Logger = std.log.scoped(.Login);

pub fn handle(
    network: *NetworkManager,
    stream: *BinaryStream,
    session: *NetherNet.Server.Session,
) !void {
    if (network.server.players.get(session) != null) return;

    const handle_started = std.Io.Clock.awake.now(network.server.io);
    defer {
        const handle_finished = std.Io.Clock.awake.now(network.server.io);
        const elapsed = handle_finished.nanoseconds - handle_started.nanoseconds;
        Logger.info("Login handler took {d} us", .{@divTrunc(elapsed, std.time.ns_per_us)});
    }

    const login = try Protocol.Packets.LoginPacket.deserialize(stream);
    Logger.info("received LoginPacket: {}", .{login.protocol});

    const job = try network.server.allocator.create(LoginJob);
    errdefer network.server.allocator.destroy(job);

    job.* = .{
        .allocator = network.server.allocator,
        .network = network,
        .session = session,
        .payload = Protocol.LoginFlow.LoginPayload.init(network.server.allocator),
    };
    errdefer job.payload.deinit();

    const payload_allocator = job.payload.arena.allocator();
    job.connection_request = .{
        .identity = try payload_allocator.dupe(u8, login.connectionRequest.identity),
        .client = try payload_allocator.dupe(u8, login.connectionRequest.client),
    };

    _ = network.server.io.async(run, .{job});
}

const LoginJob = struct {
    allocator: std.mem.Allocator,
    network: *NetworkManager,
    session: *NetherNet.Server.Session,
    payload: Protocol.LoginFlow.LoginPayload,
    connection_request: Protocol.Types.ConnectionRequest = undefined,
    owns_payload: bool = true,
};

fn run(job: *LoginJob) void {
    defer {
        if (job.owns_payload) job.payload.deinit();
        job.allocator.destroy(job);
    }

    const parse_started = std.Io.Clock.awake.now(job.network.server.io);

    var payload: [128]u8 = undefined;
    var stream = BinaryStream.init(&payload, 0);
    var status = Protocol.Packets.PlayStatusPacket{
        .status = .LoginSuccess,
    };

    Protocol.LoginFlow.LoginParser.parse(
        job.connection_request,
        &job.payload,
        job.network.server.io,
    ) catch |err| {
        Logger.err("Login failed: {s}", .{@errorName(err)});
        status.status = .LoginFailedClient;
        const serialized = status.serialize(&stream) catch {};
        job.session.sendReliable(Protocol.Packets.PlayStatusPacket.ID, serialized) catch {};
        return;
    };

    const parse_finished = std.Io.Clock.awake.now(job.network.server.io);

    const serialized = status.serialize(&stream) catch {};
    var player = Player.init(job.session, job.payload);

    job.network.server.players.put(player) catch |err| {
        Logger.err("Could not add player: {s}", .{@errorName(err)});
        player.deinit();
        return;
    };
    job.owns_payload = false;

    job.session.sendReliable(Protocol.Packets.PlayStatusPacket.ID, serialized) catch |err| {
        Logger.err("Could not send PlayStatusPacket: {s}", .{@errorName(err)});
        return;
    };

    const elapsed = parse_finished.nanoseconds - parse_started.nanoseconds;
    Logger.info("Login parsing took {d} ms", .{@divTrunc(elapsed, std.time.ns_per_ms)});
}

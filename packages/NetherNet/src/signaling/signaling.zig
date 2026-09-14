const std = @import("std");
const log = std.log.scoped(.nethernet_signaling);

pub const RequestKind = enum { capability, join };

pub const Request = struct {
    kind: RequestKind,
    network_id: ?[]const u8 = null,
};

pub const Error = error{
    InvalidPath,
    EmptyNetworkId,
    InvalidContentType,
};

pub fn parse(method: []const u8, path: []const u8) Error!Request {
    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/v1/join")) {
        log.info("capability check received: GET {s}", .{path});
        return .{ .kind = .capability };
    }

    const prefix = "/v1/join/";
    if (!std.mem.eql(u8, method, "POST") or !std.mem.startsWith(u8, path, prefix)) {
        return error.InvalidPath;
    }

    const network_id = path[prefix.len..];
    if (network_id.len == 0 or std.mem.indexOfScalar(u8, network_id, '/') != null) {
        return error.EmptyNetworkId;
    }

    log.info("join request received for NetworkID {s}", .{network_id});
    return .{ .kind = .join, .network_id = network_id };
}

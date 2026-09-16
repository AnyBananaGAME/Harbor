const std = @import("std");
const parser = @import("parser.zig");

pub const VerifyError = error{
    UnsupportedAlgorithm,
    UnknownIssuer,
    InvalidAudience,
    ExpiredToken,
    UnknownKey,
    InvalidSignature,
};

pub const IdentityVerifier = struct {
    pub fn verify(
        identity: anytype,
        modulus: []const u8,
        exponent: []const u8,
        issuer: []const u8,
        audience: []const u8,
        now: i64,
    ) !void {
        if (!std.mem.eql(u8, identity.header.alg, "RS256")) return error.UnsupportedAlgorithm;
        if (!std.mem.eql(u8, identity.payload.iss, issuer)) return error.UnknownIssuer;
        if (!std.mem.eql(u8, identity.payload.aud, audience)) return error.InvalidAudience;
        if (identity.payload.exp <= now) return error.ExpiredToken;

        const public_key = std.crypto.Certificate.rsa.PublicKey.fromBytes(exponent, modulus) catch return error.InvalidSignature;
        if (identity.signature.len != 256) return error.InvalidSignature;

        var signature: [256]u8 = undefined;
        @memcpy(&signature, identity.signature);
        std.crypto.Certificate.rsa.PKCS1v1_5Signature.verify(
            256,
            signature,
            identity.signing_input,
            public_key,
            std.crypto.hash.sha2.Sha256,
        ) catch return error.InvalidSignature;
    }
};

const Configuration = struct {
    issuer: []const u8,
    jwks_uri: []const u8,
};

const Key = struct {
    kty: []const u8,
    kid: []const u8,
    n: []const u8,
    e: []const u8,
};

const KeySet = struct {
    keys: []Key,
};

pub const LoginVerifier = struct {
    pub fn verify(
        io: std.Io,
        allocator: std.mem.Allocator,
        identity: anytype,
    ) !void {
        var configuration_buffer: [32 * 1024]u8 = undefined;
        var keys_buffer: [128 * 1024]u8 = undefined;
        var client: std.http.Client = .{ .allocator = allocator, .io = io };
        defer client.deinit();
        var writer: std.Io.Writer = .fixed(&configuration_buffer);
        const configuration_result = try client.fetch(.{
            .location = .{
                .url = "https://authorization.franchise.minecraft-services.net/.well-known/openid-configuration",
            },
            .response_writer = &writer,
        });
        if (configuration_result.status != .ok) return error.HttpRequestFailed;
        const config = try std.json.parseFromSlice(Configuration, allocator, configuration_buffer[0..writer.end], .{ .ignore_unknown_fields = true });
        defer config.deinit();
        var keys_writer: std.Io.Writer = .fixed(&keys_buffer);
        const keys_result = try client.fetch(.{
            .location = .{ .url = config.value.jwks_uri },
            .response_writer = &keys_writer,
        });
        if (keys_result.status != .ok) return error.HttpRequestFailed;
        var keys = try std.json.parseFromSlice(KeySet, allocator, keys_buffer[0..keys_writer.end], .{ .ignore_unknown_fields = true });
        defer keys.deinit();
        for (keys.value.keys) |key| {
            if (!std.mem.eql(u8, key.kty, "RSA") or !std.mem.eql(u8, key.kid, identity.header.kid)) continue;
            var modulus: [4096]u8 = undefined;
            var exponent: [16]u8 = undefined;
            const decoder = std.base64.url_safe_no_pad.Decoder;
            const modulus_bytes = modulus[0..try decoder.calcSizeForSlice(key.n)];
            const exponent_bytes = exponent[0..try decoder.calcSizeForSlice(key.e)];
            try decoder.decode(modulus_bytes, key.n);
            try decoder.decode(exponent_bytes, key.e);
            const now: i64 = @intCast(@divTrunc(std.Io.Clock.real.now(io).nanoseconds, std.time.ns_per_s));
            return IdentityVerifier.verify(
                identity,
                modulus_bytes,
                exponent_bytes,
                config.value.issuer,
                "api://auth-minecraft-services/multiplayer",
                now,
            );
        }
        return error.UnknownKey;
    }
};

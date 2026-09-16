const std = @import("std");

const BinaryStream = @import("binarystream").BinaryStream;
const ConnectionRequest = @import("../types/root.zig").ConnectionRequest;
const LoginVerifier = @import("./verifier.zig").LoginVerifier;
const SkinTypes = @import("./skin.zig");
const SkinPayload = SkinTypes.SkinPayload;

pub const ClientExtra = struct {
    ArmSize: []const u8 = "",
    ClientEditorConnectionIntent: i32 = 0,
    ClientIsEditorCapable: bool = false,
    ClientRandomId: i64 = 0,
    CompatibleWithClientSideChunkGen: bool = false,
    CurrentInputMode: i32 = 0,
    DefaultInputMode: i32 = 0,
    DeviceId: []const u8 = "",
    DeviceModel: []const u8 = "",
    DeviceOS: i32 = 0,
    FilterProfanity: bool = false,
    GameVersion: []const u8 = "",
    GraphicsMode: i32 = 0,
    GuiScale: i32 = 0,
    LanguageCode: []const u8 = "",
    MaxViewDistance: i32 = 0,
    MemoryTier: i32 = 0,
    OverrideSkin: bool = false,
    PlatformOfflineId: []const u8 = "",
    PlatformOnlineId: []const u8 = "",
    PlatformType: i32 = 0,
    ProfileHash: []const u8 = "",
    SelfSignedId: []const u8 = "",
    ServerAddress: []const u8 = "",
    ThirdPartyName: []const u8 = "",
    UIProfile: i32 = 0,
};

pub const IdentityEnvelope = struct {
    AuthenticationType: i32,
    Token: []const u8,
};

pub const IdentityHeader = struct {
    alg: []const u8,
    kid: []const u8,
    typ: []const u8,
};

pub const ClientHeader = struct {
    alg: []const u8,
    x5u: []const u8,
};

pub const IdentityPayload = struct {
    sub: []const u8,
    ipt: []const u8,
    iat: i64,
    mid: []const u8,
    tid: []const u8,
    pfcd: i64,
    cpk: []const u8,
    ap: i32,
    xid: []const u8,
    xname: []const u8,
    exp: i64,
    iss: []const u8,
    aud: []const u8,
};

// LoginPayload should hold everything related
// to the connectionrequest envelope **THAT IS REQUIRED**
// not what is just included in the envelope.
pub const LoginPayload = struct {
    arena: std.heap.ArenaAllocator,
    identity: Identity = .{},
    client: LoginData = .{},

    pub const Identity = struct {
        xname: []const u8 = &.{},
        xid: []const u8 = &.{},
        cpk: []const u8 = &.{},
    };

    pub const LoginData = struct {
        skin: SkinPayload = .{},
        extra: ClientExtra = .{},
    };

    pub fn init(allocator: std.mem.Allocator) LoginPayload {
        return .{ .arena = std.heap.ArenaAllocator.init(allocator) };
    }

    pub fn deinit(self: *LoginPayload) void {
        self.arena.deinit();
    }
};

/// Parses the login request(client and identity) and verifies the identity token.
pub const LoginParser = struct {
    pub fn parse(data: ConnectionRequest, result: *LoginPayload, io: std.Io) !void {
        try parseIdentity(data.identity, result, io);
        try parseClient(data.client, result);
    }

    fn parseIdentity(data: []const u8, result: *LoginPayload, io: std.Io) !void {
        var header_storage: [4096]u8 = undefined;
        var payload_storage: [4096]u8 = undefined;
        var signature_storage: [4096]u8 = undefined;
        const allocator = result.arena.allocator();

        const envelope = try std.json.parseFromSlice(IdentityEnvelope, allocator, data, .{});
        defer envelope.deinit();

        const token = envelope.value.Token;
        const first_dot = std.mem.indexOfScalar(u8, token, '.') orelse return error.InvalidToken;
        const second_dot = std.mem.indexOfScalarPos(u8, token, first_dot + 1, '.') orelse return error.InvalidToken;
        if (first_dot == 0 or second_dot == first_dot + 1 or second_dot + 1 >= token.len or
            std.mem.indexOfScalarPos(u8, token, second_dot + 1, '.') != null) return error.InvalidToken;

        const header_part = token[0..first_dot];
        const payload_part = token[first_dot + 1 .. second_dot];
        const signature_part = token[second_dot + 1 ..];
        const decoder = std.base64.url_safe_no_pad.Decoder;
        const header_len = try decoder.calcSizeForSlice(header_part);
        const payload_len = try decoder.calcSizeForSlice(payload_part);
        const signature_len = try decoder.calcSizeForSlice(signature_part);
        if (header_len > header_storage.len or payload_len > payload_storage.len or signature_len > signature_storage.len)
            return error.TokenTooLarge;

        const header_bytes = header_storage[0..header_len];
        const payload_bytes = payload_storage[0..payload_len];
        const signature = signature_storage[0..signature_len];

        try decoder.decode(header_bytes, header_part);
        try decoder.decode(payload_bytes, payload_part);
        try decoder.decode(signature, signature_part);

        const header = try std.json.parseFromSlice(IdentityHeader, allocator, header_bytes, .{});
        defer header.deinit();

        const payload = try std.json.parseFromSlice(IdentityPayload, allocator, payload_bytes, .{});
        defer payload.deinit();

        const token_data = .{
            .header = header.value,
            .payload = payload.value,
            .signing_input = token[0..second_dot],
            .signature = signature,
        };

        try LoginVerifier.verify(io, allocator, &token_data);

        // Allocations are under arena allocator so it's fine here
        result.identity.xname = try allocator.dupe(u8, token_data.payload.xname);
        result.identity.xid = try allocator.dupe(u8, token_data.payload.xid);
        result.identity.cpk = try allocator.dupe(u8, token_data.payload.cpk);
    }

    fn parseClient(data: []const u8, result: *LoginPayload) !void {
        const first_dot = std.mem.indexOfScalar(u8, data, '.') orelse return error.InvalidToken;
        const second_dot = std.mem.indexOfScalarPos(u8, data, first_dot + 1, '.') orelse return error.InvalidToken;

        if (first_dot == 0 or second_dot == first_dot + 1 or second_dot + 1 >= data.len or
            std.mem.indexOfScalarPos(u8, data, second_dot + 1, '.') != null) return error.InvalidToken;

        const decoder = std.base64.url_safe_no_pad.Decoder;
        const header_part = data[0..first_dot];
        const payload_part = data[first_dot + 1 .. second_dot];
        const signature_part = data[second_dot + 1 ..];

        const allocator = result.arena.allocator();
        const header = try allocator.alloc(u8, try decoder.calcSizeForSlice(header_part));
        const payload = try allocator.alloc(u8, try decoder.calcSizeForSlice(payload_part));
        const signature = try allocator.alloc(u8, try decoder.calcSizeForSlice(signature_part));

        try decoder.decode(header, header_part);
        try decoder.decode(payload, payload_part);
        try decoder.decode(signature, signature_part);

        //std.log.info("Client header: {s}", .{header});
        //std.log.info("Client payload: {s}", .{payload});

        const client_header = try std.json.parseFromSlice(ClientHeader, allocator, header, .{});
        if (!std.mem.eql(u8, client_header.value.alg, "ES384")) return error.UnsupportedClientAlgorithm;
        if (!std.mem.eql(u8, client_header.value.x5u, result.identity.cpk)) return error.InvalidClientKey;

        const key_decoder = std.base64.standard_no_pad.Decoder;
        const key_der_len = try key_decoder.calcSizeForSlice(client_header.value.x5u);
        const key_der = try allocator.alloc(u8, key_der_len);
        try key_decoder.decode(key_der, client_header.value.x5u);
        if (key_der.len < 97 or signature.len != 96) return error.InvalidClientSignature;

        const Scheme = std.crypto.sign.ecdsa.EcdsaP384Sha384;
        const public_key = try Scheme.PublicKey.fromSec1(key_der[key_der.len - 97 ..]);
        var raw_signature: [Scheme.Signature.encoded_length]u8 = undefined;
        @memcpy(&raw_signature, signature);
        Scheme.Signature.fromBytes(raw_signature).verify(data[0..second_dot], public_key) catch return error.InvalidClientSignature;

        const skin = try std.json.parseFromSlice(SkinPayload, allocator, payload, .{ .ignore_unknown_fields = true });
        const extra = try std.json.parseFromSlice(ClientExtra, allocator, payload, .{ .ignore_unknown_fields = true });

        result.client = .{
            .skin = skin.value,
            .extra = extra.value,
        };
    }
};

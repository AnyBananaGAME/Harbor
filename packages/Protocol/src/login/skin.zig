const std = @import("std");

pub const AnimatedImage = struct {
    Image: []const u8 = "",
    Type: i32 = 0,
    FrameCount: i32 = 0,
    Expression: i32 = 0,
};

pub const PersonaPiece = struct {
    PieceId: []const u8 = "",
    PieceType: []const u8 = "",
    PackId: []const u8 = "",
    IsDefault: bool = false,
    ProductId: []const u8 = "",
};

pub const PieceTintColor = struct {
    PieceType: []const u8 = "",
    Colors: [][]const u8 = &.{},
};

pub const SkinPayload = struct {
    AnimatedImageData: []AnimatedImage = &.{},
    CapeData: []const u8 = "",
    CapeId: []const u8 = "",
    CapeImageHeight: i32 = 0,
    CapeImageWidth: i32 = 0,
    CapeOnClassicSkin: bool = false,
    PersonaPieces: []PersonaPiece = &.{},
    PersonaSkin: bool = false,
    PieceTintColors: []PieceTintColor = &.{},
    PremiumSkin: bool = false,
    SkinAnimationData: []const u8 = "",
    SkinColor: []const u8 = "",
    SkinData: []const u8 = "",
    SkinGeometryData: []const u8 = "",
    SkinGeometryDataEngineVersion: []const u8 = "",
    SkinId: []const u8 = "",
    SkinImageHeight: i32 = 0,
    SkinImageWidth: i32 = 0,
    SkinResourcePatch: []const u8 = "",
    TrustedSkin: bool = false,
};

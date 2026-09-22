const std = @import("std");

pub const AttributeName = enum {
    Absorption,
    AttackDamage,
    FallDamage,
    FollowRange,
    Health,
    HorseJumpStrength,
    KnockbackResistance,
    LavaMovement,
    Luck,
    Movement,
    PlayerExhaustion,
    PlayerExperience,
    PlayerHunger,
    PlayerLevel,
    PlayerSaturation,
    UnderwaterMovement,
    ZombieSpawnReinforcements,

    pub fn toString(self: AttributeName) []const u8 {
        return switch (self) {
            .Absorption => "minecraft:absorption",
            .AttackDamage => "minecraft:attack_damage",
            .FallDamage => "minecraft:fall_damage",
            .FollowRange => "minecraft:follow_range",
            .Health => "minecraft:health",
            .HorseJumpStrength => "minecraft:horse.jump_strength",
            .KnockbackResistance => "minecraft:knockback_resistance",
            .LavaMovement => "minecraft:lava_movement",
            .Luck => "minecraft:luck",
            .Movement => "minecraft:movement",
            .PlayerExhaustion => "minecraft:player.exhaustion",
            .PlayerExperience => "minecraft:player.experience",
            .PlayerHunger => "minecraft:player.hunger",
            .PlayerLevel => "minecraft:player.level",
            .PlayerSaturation => "minecraft:player.saturation",
            .UnderwaterMovement => "minecraft:underwater_movement",
            .ZombieSpawnReinforcements => "minecraft:zombie.spawn_reinforcements",
        };
    }

    pub fn fromString(value: []const u8) ?AttributeName {
        inline for (.{ AttributeName.Absorption, .AttackDamage, .FallDamage, .FollowRange, .Health, .HorseJumpStrength, .KnockbackResistance, .LavaMovement, .Luck, .Movement, .PlayerExhaustion, .PlayerExperience, .PlayerHunger, .PlayerLevel, .PlayerSaturation, .UnderwaterMovement, .ZombieSpawnReinforcements }) |name| {
            if (std.mem.eql(u8, value, name.toString())) return name;
        }
        return null;
    }
};

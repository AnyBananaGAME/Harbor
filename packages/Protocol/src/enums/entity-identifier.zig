const std = @import("std");

pub const EntityIdentifier = enum(u16) {
    Balloon,
    Goat,
    EditorRulerIdle,
    EditorLocationPointerSelected,
    Bee,
    IceBomb,
    EditorLocationPointerIdle,
    Cushion,
    EditorRulerPointerSelected,
    EditorMapMarker,
    Minecart,
    Fox,
    Turtle,
    ZombieNautilus,
    TraderLlama,
    ThrownTrident,
    WitherSkeleton,
    SulfurCube,
    ShulkerBullet,
    Egg,
    Arrow,
    Llama,
    Horse,
    CommandBlockMinecart,
    ZombieHorse,
    TntMinecart,
    Strider,
    Agent,
    Stray,
    SmallFireball,
    SkeletonHorse,
    Husk,
    Hoglin,
    Skeleton,
    Zoglin,
    Player,
    Pig,
    Parched,
    Nautilus,
    Mule,
    HopperMinecart,
    HappyGhast,
    Donkey,
    Bogged,
    EnderDragon,
    GlowSquid,
    ChestMinecart,
    ChestBoat,
    Panda,
    CamelHusk,
    ZombieVillagerV2,
    Camel,
    CopperGolem,
    Boat,
    ZombiePigman,
    Zombie,
    VillagerV2,
    Squid,
    Sheep,
    Piglin,
    IronGolem,
    Drowned,
    Tadpole,
    Sniffer,
    Rabbit,
    Wolf,
    PolarBear,
    Ocelot,
    Blaze,
    Mooshroom,
    Enderman,
    Dolphin,
    Cow,
    Chicken,
    Cat,
    Axolotl,
    Armadillo,
    Spider,
    SnowGolem,
    Frog,
    CaveSpider,
    Allay,
    Wither,
    Guardian,
    Phantom,
    Ravager,
    Parrot,
    Ghast,
    Tropicalfish,
    Shulker,
    Salmon,
    Creeper,
    Pufferfish,
    Cod,
    ElderGuardian,
    Creaking,
    Vindicator,
    Vex,
    Silverfish,
    EnderCrystal,
    Pillager,
    Slime,
    EvocationIllager,
    WitherSkullDangerous,
    WitherSkull,
    WindChargeProjectile,
    FishingHook,
    Fireball,
    DragonFireball,
    BreezeWindChargeProjectile,
    Breeze,
    WanderingTrader,
    Villager,
    OminousItemSpawner,
    ZombieVillager,
    Witch,
    Warden,
    PiglinBrute,
    Npc,
    MagmaCube,
    LlamaSpit,
    Endermite,
    Bat,
    XpOrb,
    XpBottle,
    Tnt,
    SplashPotion,
    LingeringPotion,
    Snowball,
    EnderPearl,
    ArmorStand,
    LightningBolt,
    TripodCamera,
    FireworksRocket,
    EyeOfEnderSignal,
    AreaEffectCloud,
    _,
};

pub fn toString(self: EntityIdentifier) []const u8 {
    return switch (self) {
        .Balloon => "minecraft:balloon",
        .Goat => "minecraft:goat",
        .EditorRulerIdle => "editor:ruler_idle",
        .EditorLocationPointerSelected => "editor:location_pointer_selected",
        .Bee => "minecraft:bee",
        .IceBomb => "minecraft:ice_bomb",
        .EditorLocationPointerIdle => "editor:location_pointer_idle",
        .Cushion => "minecraft:cushion",
        .EditorRulerPointerSelected => "editor:ruler_pointer_selected",
        .EditorMapMarker => "editor:map_marker",
        .Minecart => "minecraft:minecart",
        .Fox => "minecraft:fox",
        .Turtle => "minecraft:turtle",
        .ZombieNautilus => "minecraft:zombie_nautilus",
        .TraderLlama => "minecraft:trader_llama",
        .ThrownTrident => "minecraft:thrown_trident",
        .WitherSkeleton => "minecraft:wither_skeleton",
        .SulfurCube => "minecraft:sulfur_cube",
        .ShulkerBullet => "minecraft:shulker_bullet",
        .Egg => "minecraft:egg",
        .Arrow => "minecraft:arrow",
        .Llama => "minecraft:llama",
        .Horse => "minecraft:horse",
        .CommandBlockMinecart => "minecraft:command_block_minecart",
        .ZombieHorse => "minecraft:zombie_horse",
        .TntMinecart => "minecraft:tnt_minecart",
        .Strider => "minecraft:strider",
        .Agent => "minecraft:agent",
        .Stray => "minecraft:stray",
        .SmallFireball => "minecraft:small_fireball",
        .SkeletonHorse => "minecraft:skeleton_horse",
        .Husk => "minecraft:husk",
        .Hoglin => "minecraft:hoglin",
        .Skeleton => "minecraft:skeleton",
        .Zoglin => "minecraft:zoglin",
        .Player => "minecraft:player",
        .Pig => "minecraft:pig",
        .Parched => "minecraft:parched",
        .Nautilus => "minecraft:nautilus",
        .Mule => "minecraft:mule",
        .HopperMinecart => "minecraft:hopper_minecart",
        .HappyGhast => "minecraft:happy_ghast",
        .Donkey => "minecraft:donkey",
        .Bogged => "minecraft:bogged",
        .EnderDragon => "minecraft:ender_dragon",
        .GlowSquid => "minecraft:glow_squid",
        .ChestMinecart => "minecraft:chest_minecart",
        .ChestBoat => "minecraft:chest_boat",
        .Panda => "minecraft:panda",
        .CamelHusk => "minecraft:camel_husk",
        .ZombieVillagerV2 => "minecraft:zombie_villager_v2",
        .Camel => "minecraft:camel",
        .CopperGolem => "minecraft:copper_golem",
        .Boat => "minecraft:boat",
        .ZombiePigman => "minecraft:zombie_pigman",
        .Zombie => "minecraft:zombie",
        .VillagerV2 => "minecraft:villager_v2",
        .Squid => "minecraft:squid",
        .Sheep => "minecraft:sheep",
        .Piglin => "minecraft:piglin",
        .IronGolem => "minecraft:iron_golem",
        .Drowned => "minecraft:drowned",
        .Tadpole => "minecraft:tadpole",
        .Sniffer => "minecraft:sniffer",
        .Rabbit => "minecraft:rabbit",
        .Wolf => "minecraft:wolf",
        .PolarBear => "minecraft:polar_bear",
        .Ocelot => "minecraft:ocelot",
        .Blaze => "minecraft:blaze",
        .Mooshroom => "minecraft:mooshroom",
        .Enderman => "minecraft:enderman",
        .Dolphin => "minecraft:dolphin",
        .Cow => "minecraft:cow",
        .Chicken => "minecraft:chicken",
        .Cat => "minecraft:cat",
        .Axolotl => "minecraft:axolotl",
        .Armadillo => "minecraft:armadillo",
        .Spider => "minecraft:spider",
        .SnowGolem => "minecraft:snow_golem",
        .Frog => "minecraft:frog",
        .CaveSpider => "minecraft:cave_spider",
        .Allay => "minecraft:allay",
        .Wither => "minecraft:wither",
        .Guardian => "minecraft:guardian",
        .Phantom => "minecraft:phantom",
        .Ravager => "minecraft:ravager",
        .Parrot => "minecraft:parrot",
        .Ghast => "minecraft:ghast",
        .Tropicalfish => "minecraft:tropicalfish",
        .Shulker => "minecraft:shulker",
        .Salmon => "minecraft:salmon",
        .Creeper => "minecraft:creeper",
        .Pufferfish => "minecraft:pufferfish",
        .Cod => "minecraft:cod",
        .ElderGuardian => "minecraft:elder_guardian",
        .Creaking => "minecraft:creaking",
        .Vindicator => "minecraft:vindicator",
        .Vex => "minecraft:vex",
        .Silverfish => "minecraft:silverfish",
        .EnderCrystal => "minecraft:ender_crystal",
        .Pillager => "minecraft:pillager",
        .Slime => "minecraft:slime",
        .EvocationIllager => "minecraft:evocation_illager",
        .WitherSkullDangerous => "minecraft:wither_skull_dangerous",
        .WitherSkull => "minecraft:wither_skull",
        .WindChargeProjectile => "minecraft:wind_charge_projectile",
        .FishingHook => "minecraft:fishing_hook",
        .Fireball => "minecraft:fireball",
        .DragonFireball => "minecraft:dragon_fireball",
        .BreezeWindChargeProjectile => "minecraft:breeze_wind_charge_projectile",
        .Breeze => "minecraft:breeze",
        .WanderingTrader => "minecraft:wandering_trader",
        .Villager => "minecraft:villager",
        .OminousItemSpawner => "minecraft:ominous_item_spawner",
        .ZombieVillager => "minecraft:zombie_villager",
        .Witch => "minecraft:witch",
        .Warden => "minecraft:warden",
        .PiglinBrute => "minecraft:piglin_brute",
        .Npc => "minecraft:npc",
        .MagmaCube => "minecraft:magma_cube",
        .LlamaSpit => "minecraft:llama_spit",
        .Endermite => "minecraft:endermite",
        .Bat => "minecraft:bat",
        .XpOrb => "minecraft:xp_orb",
        .XpBottle => "minecraft:xp_bottle",
        .Tnt => "minecraft:tnt",
        .SplashPotion => "minecraft:splash_potion",
        .LingeringPotion => "minecraft:lingering_potion",
        .Snowball => "minecraft:snowball",
        .EnderPearl => "minecraft:ender_pearl",
        .ArmorStand => "minecraft:armor_stand",
        .LightningBolt => "minecraft:lightning_bolt",
        .TripodCamera => "minecraft:tripod_camera",
        .FireworksRocket => "minecraft:fireworks_rocket",
        .EyeOfEnderSignal => "minecraft:eye_of_ender_signal",
        .AreaEffectCloud => "minecraft:area_effect_cloud",
        ._ => "",
    };
}

pub fn fromString(value: []const u8) ?EntityIdentifier {
    if (std.mem.eql(u8, value, "minecraft:balloon")) return .Balloon;
    if (std.mem.eql(u8, value, "minecraft:goat")) return .Goat;
    if (std.mem.eql(u8, value, "editor:ruler_idle")) return .EditorRulerIdle;
    if (std.mem.eql(u8, value, "editor:location_pointer_selected")) return .EditorLocationPointerSelected;
    if (std.mem.eql(u8, value, "minecraft:bee")) return .Bee;
    if (std.mem.eql(u8, value, "minecraft:ice_bomb")) return .IceBomb;
    if (std.mem.eql(u8, value, "editor:location_pointer_idle")) return .EditorLocationPointerIdle;
    if (std.mem.eql(u8, value, "minecraft:cushion")) return .Cushion;
    if (std.mem.eql(u8, value, "editor:ruler_pointer_selected")) return .EditorRulerPointerSelected;
    if (std.mem.eql(u8, value, "editor:map_marker")) return .EditorMapMarker;
    if (std.mem.eql(u8, value, "minecraft:minecart")) return .Minecart;
    if (std.mem.eql(u8, value, "minecraft:fox")) return .Fox;
    if (std.mem.eql(u8, value, "minecraft:turtle")) return .Turtle;
    if (std.mem.eql(u8, value, "minecraft:zombie_nautilus")) return .ZombieNautilus;
    if (std.mem.eql(u8, value, "minecraft:trader_llama")) return .TraderLlama;
    if (std.mem.eql(u8, value, "minecraft:thrown_trident")) return .ThrownTrident;
    if (std.mem.eql(u8, value, "minecraft:wither_skeleton")) return .WitherSkeleton;
    if (std.mem.eql(u8, value, "minecraft:sulfur_cube")) return .SulfurCube;
    if (std.mem.eql(u8, value, "minecraft:shulker_bullet")) return .ShulkerBullet;
    if (std.mem.eql(u8, value, "minecraft:egg")) return .Egg;
    if (std.mem.eql(u8, value, "minecraft:arrow")) return .Arrow;
    if (std.mem.eql(u8, value, "minecraft:llama")) return .Llama;
    if (std.mem.eql(u8, value, "minecraft:horse")) return .Horse;
    if (std.mem.eql(u8, value, "minecraft:command_block_minecart")) return .CommandBlockMinecart;
    if (std.mem.eql(u8, value, "minecraft:zombie_horse")) return .ZombieHorse;
    if (std.mem.eql(u8, value, "minecraft:tnt_minecart")) return .TntMinecart;
    if (std.mem.eql(u8, value, "minecraft:strider")) return .Strider;
    if (std.mem.eql(u8, value, "minecraft:agent")) return .Agent;
    if (std.mem.eql(u8, value, "minecraft:stray")) return .Stray;
    if (std.mem.eql(u8, value, "minecraft:small_fireball")) return .SmallFireball;
    if (std.mem.eql(u8, value, "minecraft:skeleton_horse")) return .SkeletonHorse;
    if (std.mem.eql(u8, value, "minecraft:husk")) return .Husk;
    if (std.mem.eql(u8, value, "minecraft:hoglin")) return .Hoglin;
    if (std.mem.eql(u8, value, "minecraft:skeleton")) return .Skeleton;
    if (std.mem.eql(u8, value, "minecraft:zoglin")) return .Zoglin;
    if (std.mem.eql(u8, value, "minecraft:player")) return .Player;
    if (std.mem.eql(u8, value, "minecraft:pig")) return .Pig;
    if (std.mem.eql(u8, value, "minecraft:parched")) return .Parched;
    if (std.mem.eql(u8, value, "minecraft:nautilus")) return .Nautilus;
    if (std.mem.eql(u8, value, "minecraft:mule")) return .Mule;
    if (std.mem.eql(u8, value, "minecraft:hopper_minecart")) return .HopperMinecart;
    if (std.mem.eql(u8, value, "minecraft:happy_ghast")) return .HappyGhast;
    if (std.mem.eql(u8, value, "minecraft:donkey")) return .Donkey;
    if (std.mem.eql(u8, value, "minecraft:bogged")) return .Bogged;
    if (std.mem.eql(u8, value, "minecraft:ender_dragon")) return .EnderDragon;
    if (std.mem.eql(u8, value, "minecraft:glow_squid")) return .GlowSquid;
    if (std.mem.eql(u8, value, "minecraft:chest_minecart")) return .ChestMinecart;
    if (std.mem.eql(u8, value, "minecraft:chest_boat")) return .ChestBoat;
    if (std.mem.eql(u8, value, "minecraft:panda")) return .Panda;
    if (std.mem.eql(u8, value, "minecraft:camel_husk")) return .CamelHusk;
    if (std.mem.eql(u8, value, "minecraft:zombie_villager_v2")) return .ZombieVillagerV2;
    if (std.mem.eql(u8, value, "minecraft:camel")) return .Camel;
    if (std.mem.eql(u8, value, "minecraft:copper_golem")) return .CopperGolem;
    if (std.mem.eql(u8, value, "minecraft:boat")) return .Boat;
    if (std.mem.eql(u8, value, "minecraft:zombie_pigman")) return .ZombiePigman;
    if (std.mem.eql(u8, value, "minecraft:zombie")) return .Zombie;
    if (std.mem.eql(u8, value, "minecraft:villager_v2")) return .VillagerV2;
    if (std.mem.eql(u8, value, "minecraft:squid")) return .Squid;
    if (std.mem.eql(u8, value, "minecraft:sheep")) return .Sheep;
    if (std.mem.eql(u8, value, "minecraft:piglin")) return .Piglin;
    if (std.mem.eql(u8, value, "minecraft:iron_golem")) return .IronGolem;
    if (std.mem.eql(u8, value, "minecraft:drowned")) return .Drowned;
    if (std.mem.eql(u8, value, "minecraft:tadpole")) return .Tadpole;
    if (std.mem.eql(u8, value, "minecraft:sniffer")) return .Sniffer;
    if (std.mem.eql(u8, value, "minecraft:rabbit")) return .Rabbit;
    if (std.mem.eql(u8, value, "minecraft:wolf")) return .Wolf;
    if (std.mem.eql(u8, value, "minecraft:polar_bear")) return .PolarBear;
    if (std.mem.eql(u8, value, "minecraft:ocelot")) return .Ocelot;
    if (std.mem.eql(u8, value, "minecraft:blaze")) return .Blaze;
    if (std.mem.eql(u8, value, "minecraft:mooshroom")) return .Mooshroom;
    if (std.mem.eql(u8, value, "minecraft:enderman")) return .Enderman;
    if (std.mem.eql(u8, value, "minecraft:dolphin")) return .Dolphin;
    if (std.mem.eql(u8, value, "minecraft:cow")) return .Cow;
    if (std.mem.eql(u8, value, "minecraft:chicken")) return .Chicken;
    if (std.mem.eql(u8, value, "minecraft:cat")) return .Cat;
    if (std.mem.eql(u8, value, "minecraft:axolotl")) return .Axolotl;
    if (std.mem.eql(u8, value, "minecraft:armadillo")) return .Armadillo;
    if (std.mem.eql(u8, value, "minecraft:spider")) return .Spider;
    if (std.mem.eql(u8, value, "minecraft:snow_golem")) return .SnowGolem;
    if (std.mem.eql(u8, value, "minecraft:frog")) return .Frog;
    if (std.mem.eql(u8, value, "minecraft:cave_spider")) return .CaveSpider;
    if (std.mem.eql(u8, value, "minecraft:allay")) return .Allay;
    if (std.mem.eql(u8, value, "minecraft:wither")) return .Wither;
    if (std.mem.eql(u8, value, "minecraft:guardian")) return .Guardian;
    if (std.mem.eql(u8, value, "minecraft:phantom")) return .Phantom;
    if (std.mem.eql(u8, value, "minecraft:ravager")) return .Ravager;
    if (std.mem.eql(u8, value, "minecraft:parrot")) return .Parrot;
    if (std.mem.eql(u8, value, "minecraft:ghast")) return .Ghast;
    if (std.mem.eql(u8, value, "minecraft:tropicalfish")) return .Tropicalfish;
    if (std.mem.eql(u8, value, "minecraft:shulker")) return .Shulker;
    if (std.mem.eql(u8, value, "minecraft:salmon")) return .Salmon;
    if (std.mem.eql(u8, value, "minecraft:creeper")) return .Creeper;
    if (std.mem.eql(u8, value, "minecraft:pufferfish")) return .Pufferfish;
    if (std.mem.eql(u8, value, "minecraft:cod")) return .Cod;
    if (std.mem.eql(u8, value, "minecraft:elder_guardian")) return .ElderGuardian;
    if (std.mem.eql(u8, value, "minecraft:creaking")) return .Creaking;
    if (std.mem.eql(u8, value, "minecraft:vindicator")) return .Vindicator;
    if (std.mem.eql(u8, value, "minecraft:vex")) return .Vex;
    if (std.mem.eql(u8, value, "minecraft:silverfish")) return .Silverfish;
    if (std.mem.eql(u8, value, "minecraft:ender_crystal")) return .EnderCrystal;
    if (std.mem.eql(u8, value, "minecraft:pillager")) return .Pillager;
    if (std.mem.eql(u8, value, "minecraft:slime")) return .Slime;
    if (std.mem.eql(u8, value, "minecraft:evocation_illager")) return .EvocationIllager;
    if (std.mem.eql(u8, value, "minecraft:wither_skull_dangerous")) return .WitherSkullDangerous;
    if (std.mem.eql(u8, value, "minecraft:wither_skull")) return .WitherSkull;
    if (std.mem.eql(u8, value, "minecraft:wind_charge_projectile")) return .WindChargeProjectile;
    if (std.mem.eql(u8, value, "minecraft:fishing_hook")) return .FishingHook;
    if (std.mem.eql(u8, value, "minecraft:fireball")) return .Fireball;
    if (std.mem.eql(u8, value, "minecraft:dragon_fireball")) return .DragonFireball;
    if (std.mem.eql(u8, value, "minecraft:breeze_wind_charge_projectile")) return .BreezeWindChargeProjectile;
    if (std.mem.eql(u8, value, "minecraft:breeze")) return .Breeze;
    if (std.mem.eql(u8, value, "minecraft:wandering_trader")) return .WanderingTrader;
    if (std.mem.eql(u8, value, "minecraft:villager")) return .Villager;
    if (std.mem.eql(u8, value, "minecraft:ominous_item_spawner")) return .OminousItemSpawner;
    if (std.mem.eql(u8, value, "minecraft:zombie_villager")) return .ZombieVillager;
    if (std.mem.eql(u8, value, "minecraft:witch")) return .Witch;
    if (std.mem.eql(u8, value, "minecraft:warden")) return .Warden;
    if (std.mem.eql(u8, value, "minecraft:piglin_brute")) return .PiglinBrute;
    if (std.mem.eql(u8, value, "minecraft:npc")) return .Npc;
    if (std.mem.eql(u8, value, "minecraft:magma_cube")) return .MagmaCube;
    if (std.mem.eql(u8, value, "minecraft:llama_spit")) return .LlamaSpit;
    if (std.mem.eql(u8, value, "minecraft:endermite")) return .Endermite;
    if (std.mem.eql(u8, value, "minecraft:bat")) return .Bat;
    if (std.mem.eql(u8, value, "minecraft:xp_orb")) return .XpOrb;
    if (std.mem.eql(u8, value, "minecraft:xp_bottle")) return .XpBottle;
    if (std.mem.eql(u8, value, "minecraft:tnt")) return .Tnt;
    if (std.mem.eql(u8, value, "minecraft:splash_potion")) return .SplashPotion;
    if (std.mem.eql(u8, value, "minecraft:lingering_potion")) return .LingeringPotion;
    if (std.mem.eql(u8, value, "minecraft:snowball")) return .Snowball;
    if (std.mem.eql(u8, value, "minecraft:ender_pearl")) return .EnderPearl;
    if (std.mem.eql(u8, value, "minecraft:armor_stand")) return .ArmorStand;
    if (std.mem.eql(u8, value, "minecraft:lightning_bolt")) return .LightningBolt;
    if (std.mem.eql(u8, value, "minecraft:tripod_camera")) return .TripodCamera;
    if (std.mem.eql(u8, value, "minecraft:fireworks_rocket")) return .FireworksRocket;
    if (std.mem.eql(u8, value, "minecraft:eye_of_ender_signal")) return .EyeOfEnderSignal;
    if (std.mem.eql(u8, value, "minecraft:area_effect_cloud")) return .AreaEffectCloud;
    return null;
}

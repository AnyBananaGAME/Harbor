const std = @import("std");
const Generator = @import("./generator.zig").Generator;

pub const GeneratorFactory = *const fn (
    allocator: std.mem.Allocator,
    seed: i64,
) anyerror!Generator;

/// Ugh basically a registry for generators and works as a factory
/// by constructing generators
pub const GeneratorRegistry = struct {
    /// The allocator used to allocate memory for generators.
    allocator: std.mem.Allocator,

    /// The map of generator factories, keyed by generator name.
    factories: std.StringHashMapUnmanaged(GeneratorFactory) = .empty,

    /// Initializes the generator registry with the given allocator.
    pub fn init(allocator: std.mem.Allocator) GeneratorRegistry {
        return .{ .allocator = allocator };
    }

    /// Deinitializes the generator registry, freeing any allocated memory.
    pub fn deinit(
        self: *GeneratorRegistry,
    ) void {
        self.factories.deinit(self.allocator);
    }

    /// Registers a generator factory with the given name.
    pub fn register(
        self: *GeneratorRegistry,
        name: []const u8,
        factory: GeneratorFactory,
    ) !void {
        try self.factories.put(self.allocator, name, factory);
    }

    /// Creates a generator using the registered factory with the given name.
    pub fn create(
        self: *const GeneratorRegistry,
        name: []const u8,
        seed: i64,
    ) !Generator {
        const factory = self.factories.get(name) orelse
            return error.GeneratorNotFound;

        return factory(self.allocator, seed);
    }
};

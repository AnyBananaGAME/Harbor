const Protocol = @import("Protocol");
const ChunkPos = Protocol.Types.ChunkPos;
const SubChunk = @import("sub-chunk.zig").SubChunk;

pub const Chunk = struct {
    /// The position of the chunk in the world. {x, z}
    position: ChunkPos,

    /// The sub-chunks in the chunk.
    sub_chunks: []SubChunk,
};

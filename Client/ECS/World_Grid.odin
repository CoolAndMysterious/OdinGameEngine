package ECS

CHUNK_SIZE       :: 64
CHUNK_CELL_COUNT :: CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE


WORLD_SIZE :: 8192
WORLD_CHUNKS_PER_AXIS :: WORLD_SIZE / CHUNK_SIZE

WORLD_MIN_CHUNK :: -(WORLD_CHUNKS_PER_AXIS / 2)
WORLD_MAX_CHUNK ::  (WORLD_CHUNKS_PER_AXIS / 2) - 1

Chunk_Coord :: [3]int


Material :: enum u8 {
    Air,
    Dirt,
    Rock,
    Mud,
    Sand,
}


Chunk :: struct {
    density:  [dynamic]f16,
    material: [dynamic]Material,

    active: bool,
}


World_Grid :: struct {
    chunks: map[Chunk_Coord]Chunk,
}
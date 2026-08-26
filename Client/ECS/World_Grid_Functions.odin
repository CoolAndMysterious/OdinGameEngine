package ECS


create_world_grid :: proc() -> ^World_Grid {
    world := new(World_Grid)

    world.chunks = make(map[Chunk_Coord]Chunk)

    return world
}

create_chunk :: proc() -> Chunk {
    chunk := Chunk{}

    chunk.density = make([dynamic]f16, CHUNK_CELL_COUNT)
    chunk.material = make([dynamic]Material, CHUNK_CELL_COUNT)

    chunk.active = true

    return chunk
}


chunk_coord_is_valid :: proc(coord: Chunk_Coord) -> bool {
    return (
        coord.x >= WORLD_MIN_CHUNK &&
        coord.x <= WORLD_MAX_CHUNK &&

        coord.y >= WORLD_MIN_CHUNK &&
        coord.y <= WORLD_MAX_CHUNK &&

        coord.z >= WORLD_MIN_CHUNK &&
        coord.z <= WORLD_MAX_CHUNK
    )
}

create_chunk_at :: proc( world: ^World_Grid, coord: Chunk_Coord, ) -> (bool) {

    if !chunk_coord_is_valid(coord) {
        return false
    }

    if coord in world.chunks {
        return false
    }

    world.chunks[coord] = create_chunk()

    return true
}
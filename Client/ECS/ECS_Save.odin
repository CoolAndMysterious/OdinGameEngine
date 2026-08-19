package ECS

import "core:encoding/cbor"
import "core:os"


SAVE_VERSION :: 1
path := "saves/"


Save_State :: struct {
    version:         u32,

    entity_capacity: int,
    next_entity:     Entity,

    entity_state: [dynamic]Entity_State,
    free_entities: [dynamic]Entity,

    // Stored as u8 instead of Tag_Bits so the save format
    // does not depend on the internal representation of
    // Odin's bit_set.
    tags: [dynamic]u8,

    // Normal arrays for serialization.
    positions: [dynamic]Position,
    rotations: [dynamic]Rotation,
    velocities: [dynamic]Velocity,
}


save_world :: proc(world: ^World) -> bool {

    save := Save_State{
        version         = SAVE_VERSION,
        entity_capacity = world.entity_capacity,
        next_entity     = world.next_entity,
    }

    // ENTITY STATE

    reserve(&save.entity_state, len(world.entity_state))
    for state in world.entity_state {
        append(&save.entity_state, state)
    }

    // FREE ENTITY IDs
   
    reserve(&save.free_entities, len(world.free_entities))
    for entity in world.free_entities {
        append(&save.free_entities, entity)
    }

    // TAGS

    reserve(&save.tags, len(world.tags))
    for tags in world.tags {
        bits: u8 = 0

        for tag in Tag {
            if tag in tags {
                bits |= u8(1) << u8(tag)
            }
        }

        append(&save.tags, bits)
    }

    // POSITIONS
   
    reserve(&save.positions, len(world.positions))
    for i in 0 ..< len(world.positions) {
        append(&save.positions, world.positions[i])
    }

    // ROTATIONS
   
    reserve(&save.rotations, len(world.rotations))
    for i in 0 ..< len(world.rotations) {
        append(&save.rotations, world.rotations[i])
    }
   
    // VELOCITIES
   
    reserve(&save.velocities, len(world.velocities))
    for i in 0 ..< len(world.velocities) {
        append(&save.velocities, world.velocities[i])
    }

    // CBOR
   
    data, err := cbor.marshal( save, cbor.ENCODE_SMALL, )
    if err != nil {
        return false
    }

    defer delete(data)

    // WRITE FILE

    file_err := os.write_entire_file_from_bytes(path, data)
    if file_err != nil {
        return false
    }

    return true
}


load_world :: proc() -> (World, bool) {

    world := World{}

    // READ FILE
    
    data, err := os.read_entire_file_from_path(path, context.allocator)

    if err != nil {
        return world, false
    }

    defer delete(data)

    // UNMARSHAL CBOR

    save := Save_State{}

    err_cbor := cbor.unmarshal_from_bytes(data, &save)

    if err_cbor != nil {
        return world, false
    }

    defer delete(save.entity_state)
    defer delete(save.free_entities)
    defer delete(save.tags)
    defer delete(save.positions)
    defer delete(save.rotations)
    defer delete(save.velocities)



    // VALIDATE SAVE

    if save.version != SAVE_VERSION {
        return world, false
    }

    if save.entity_capacity < 0 {
        return world, false
    }

    // All entity-indexed data must have the same length.
    if len(save.entity_state) != len(save.tags) {
        return world, false
    }

    if len(save.entity_state) != len(save.positions) {
        return world, false
    }

    if len(save.entity_state) != len(save.rotations) {
        return world, false
    }

    if len(save.entity_state) != len(save.velocities) {
        return world, false
    }

    // The saved capacity cannot be smaller than the
    // entity-indexed storage that was saved.
    if save.entity_capacity < len(save.entity_state) {
        return world, false
    }



    // CREATE WORLD STORAGE
    world = create_world(save.entity_capacity)
    world.next_entity = save.next_entity

    // RESTORE ENTITY STATE

    copy(
        world.entity_state[:],
        save.entity_state[:],
    )

    // RESTORE FREE ENTITY LIST

    resize(
        &world.free_entities,
        len(save.free_entities),
    )

    copy(
        world.free_entities[:],
        save.free_entities[:],
    )

    // RESTORE TAGS

    for i in 0 ..< len(save.tags) {
        bits := save.tags[i]

        world.tags[i] = {}

        for tag in Tag {
            mask := u8(1) << u8(tag)

            if (bits & mask) != 0 {
                world.tags[i] += {tag}
            }
        }
    }

    // RESTORE POSITIONS

    for i in 0 ..< len(save.positions) {
        world.positions[i] = save.positions[i]
    }

    // RESTORE ROTATIONS

    for i in 0 ..< len(save.rotations) {
        world.rotations[i] = save.rotations[i]
    }

    // RESTORE VELOCITIES

    for i in 0 ..< len(save.velocities) {
        world.velocities[i] = save.velocities[i]
    }

    return world, true
}
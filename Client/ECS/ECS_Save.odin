package ECS

import "core:encoding/cbor"
import "core:os"
import "core:fmt"


SAVE_VERSION :: 1
SAVE_PATH :: "saves/world_save.cbor"


Save_State :: struct {
    version: u32,

    // ============================================
    // ECS WORLD
    // ============================================

    entity_capacity: int,
    next_entity: Entity,

    entity_state: [dynamic]Entity_State,
    free_entities: [dynamic]Entity,

    // Stored as u8 instead of Tag_Bits so the save
    // format does not depend on Odin's bit_set
    // representation.
    tags: [dynamic]u8,

    positions: [dynamic]Position,
    rotations: [dynamic]Rotation,
    velocities: [dynamic]Velocity,
}


save_world :: proc(world: ^World) -> bool {

    ecs := &world.ecs_world

    save := Save_State{
        version         = SAVE_VERSION,
        entity_capacity = ecs.entity_capacity,
        next_entity     = ecs.next_entity,
    }

    // ============================================================
    // ENTITY STATE
    // ============================================================

    reserve(&save.entity_state, len(ecs.entity_state))

    for state in ecs.entity_state {
        append(&save.entity_state, state)
    }


    // ============================================================
    // FREE ENTITY IDs
    // ============================================================

    reserve(&save.free_entities, len(ecs.free_entities))

    for entity in ecs.free_entities {
        append(&save.free_entities, entity)
    }


    // ============================================================
    // TAGS
    // ============================================================

    reserve(&save.tags, len(ecs.tags))

    for tags in ecs.tags {
        bits: u8 = 0

        for tag in Tag {
            if tag in tags {
                bits |= u8(1) << u8(tag)
            }
        }

        append(&save.tags, bits)
    }


    // ============================================================
    // POSITIONS
    // ============================================================

    reserve(&save.positions, len(ecs.positions))

    for i in 0 ..< len(ecs.positions) {
        append(&save.positions, ecs.positions[i])
    }


    // ============================================================
    // ROTATIONS
    // ============================================================

    reserve(&save.rotations, len(ecs.rotations))

    for i in 0 ..< len(ecs.rotations) {
        append(&save.rotations, ecs.rotations[i])
    }


    // ============================================================
    // VELOCITIES
    // ============================================================

    reserve(&save.velocities, len(ecs.velocities))

    for i in 0 ..< len(ecs.velocities) {
        append(&save.velocities, ecs.velocities[i])
    }


    // ============================================================
    // CBOR
    // ============================================================

    data, err := cbor.marshal(
        save,
        cbor.ENCODE_SMALL,
    )

    if err != nil {
        return false
    }

    defer delete(data)


    // ============================================================
    // WRITE FILE
    // ============================================================

    file_err := os.write_entire_file_from_bytes(
        SAVE_PATH,
        data,
    )

    if file_err != nil {
        return false
    }

    return true
}


load_world :: proc(world: ^World) -> bool {

    fmt.println("[LOAD] Starting...")

    // ========================================================
    // READ FILE
    // ========================================================

    fmt.println("[LOAD] Reading file...")

    data, err := os.read_entire_file_from_path(
        SAVE_PATH,
        context.allocator,
    )

    if err != nil {
        fmt.println("[LOAD] ERROR: Could not read save file.")
        fmt.println("[LOAD] Error:", err)
        return false
    }

    defer delete(data)

    fmt.println("[LOAD] File read.")
    fmt.println("[LOAD] Bytes:", len(data))


    // ========================================================
    // UNMARSHAL CBOR
    // ========================================================

    fmt.println("[LOAD] Decoding CBOR...")

    save := Save_State{}

    err_cbor := cbor.unmarshal_from_bytes(
        data,
        &save,
    )

    if err_cbor != nil {
        fmt.println("[LOAD] ERROR: CBOR decode failed.")
        fmt.println("[LOAD] Error:", err_cbor)
        return false
    }

    fmt.println("[LOAD] CBOR decoded.")

    // The decoded Save_State owns dynamically allocated arrays.
    // They are no longer needed after we copy everything into
    // the runtime ECS world.
    defer delete(save.entity_state)
    defer delete(save.free_entities)
    defer delete(save.tags)
    defer delete(save.positions)
    defer delete(save.rotations)
    defer delete(save.velocities)


    // ========================================================
    // VALIDATE SAVE
    // ========================================================

    fmt.println("[LOAD] Validating save...")

    if save.version != SAVE_VERSION {
        fmt.println("[LOAD] ERROR: Wrong save version.")
        return false
    }

    if save.entity_capacity < 0 {
        fmt.println("[LOAD] ERROR: Invalid entity capacity.")
        return false
    }

    // Every entity-indexed array must contain the same
    // number of slots.
    if len(save.entity_state) != len(save.tags) {
        fmt.println("[LOAD] ERROR: entity_state/tags mismatch.")
        return false
    }

    if len(save.entity_state) != len(save.positions) {
        fmt.println("[LOAD] ERROR: entity_state/positions mismatch.")
        return false
    }

    if len(save.entity_state) != len(save.rotations) {
        fmt.println("[LOAD] ERROR: entity_state/rotations mismatch.")
        return false
    }

    if len(save.entity_state) != len(save.velocities) {
        fmt.println("[LOAD] ERROR: entity_state/velocities mismatch.")
        return false
    }

    // Saved storage cannot exceed the saved capacity.
    if len(save.entity_state) > save.entity_capacity {
        fmt.println("[LOAD] ERROR: Entity storage exceeds capacity.")
        return false
    }

    // next_entity must point within the range of entity IDs
    // that have been allocated historically.
    if int(save.next_entity) > save.entity_capacity {
        fmt.println("[LOAD] ERROR: next_entity exceeds capacity.")
        return false
    }

    fmt.println("[LOAD] Save validated.")
    fmt.println("[LOAD] Capacity:", save.entity_capacity)
    fmt.println("[LOAD] Entity slots:", len(save.entity_state))
    fmt.println("[LOAD] Free IDs:", len(save.free_entities))


    // ========================================================
    // ECS WORLD
    // ========================================================

    ecs := &world.ecs_world

    fmt.println("[LOAD] Restoring ECS world...")


    // ========================================================
    // RESTORE METADATA
    // ========================================================

    ecs.entity_capacity = save.entity_capacity
    ecs.next_entity = save.next_entity

    fmt.println("[LOAD] ECS metadata restored.")


    // ========================================================
    // RESIZE ENTITY STORAGE
    // ========================================================

    fmt.println("[LOAD] Resizing entity_state...")

    err_resize := resize(
        &ecs.entity_state,
        save.entity_capacity,
    )

    if err_resize != nil {
        fmt.println("[LOAD] ERROR: entity_state resize failed.")
        fmt.println("[LOAD] Error:", err_resize)
        return false
    }


    fmt.println("[LOAD] Resizing tags...")

    err_resize = resize(
        &ecs.tags,
        save.entity_capacity,
    )

    if err_resize != nil {
        fmt.println("[LOAD] ERROR: tags resize failed.")
        fmt.println("[LOAD] Error:", err_resize)
        return false
    }


    fmt.println("[LOAD] Resizing positions...")

    err_resize = resize(
        &ecs.positions,
        save.entity_capacity,
    )

    if err_resize != nil {
        fmt.println("[LOAD] ERROR: positions resize failed.")
        fmt.println("[LOAD] Error:", err_resize)
        return false
    }


    fmt.println("[LOAD] Resizing rotations...")

    err_resize = resize(
        &ecs.rotations,
        save.entity_capacity,
    )

    if err_resize != nil {
        fmt.println("[LOAD] ERROR: rotations resize failed.")
        fmt.println("[LOAD] Error:", err_resize)
        return false
    }


    fmt.println("[LOAD] Resizing velocities...")

    err_resize = resize(
        &ecs.velocities,
        save.entity_capacity,
    )

    if err_resize != nil {
        fmt.println("[LOAD] ERROR: velocities resize failed.")
        fmt.println("[LOAD] Error:", err_resize)
        return false
    }

    fmt.println("[LOAD] ECS storage resized.")


    // ========================================================
    // RESTORE ENTITY STATE
    // ========================================================

    fmt.println("[LOAD] Restoring entity states...")

    for i in 0 ..< len(save.entity_state) {
        ecs.entity_state[i] = save.entity_state[i]
    }


    // ========================================================
    // RESTORE FREE ENTITY IDs
    // ========================================================

    fmt.println("[LOAD] Restoring free IDs...")

    err_resize = resize(
        &ecs.free_entities,
        len(save.free_entities),
    )

    if err_resize != nil {
        fmt.println("[LOAD] ERROR: free_entities resize failed.")
        fmt.println("[LOAD] Error:", err_resize)
        return false
    }

    for i in 0 ..< len(save.free_entities) {
        ecs.free_entities[i] = save.free_entities[i]
    }


    // ========================================================
    // RESTORE TAGS
    // ========================================================

    fmt.println("[LOAD] Restoring tags...")

    for i in 0 ..< len(save.tags) {

        bits := save.tags[i]

        ecs.tags[i] = {}

        for tag in Tag {

            mask := u8(1) << u8(tag)

            if (bits & mask) != 0 {
                ecs.tags[i] += {tag}
            }
        }
    }


    // ========================================================
    // RESTORE POSITIONS
    // ========================================================

    fmt.println("[LOAD] Restoring positions...")

    for i in 0 ..< len(save.positions) {
        ecs.positions[i] = save.positions[i]
    }


    // ========================================================
    // RESTORE ROTATIONS
    // ========================================================

    fmt.println("[LOAD] Restoring rotations...")

    for i in 0 ..< len(save.rotations) {
        ecs.rotations[i] = save.rotations[i]
    }


    // ========================================================
    // RESTORE VELOCITIES
    // ========================================================

    fmt.println("[LOAD] Restoring velocities...")

    for i in 0 ..< len(save.velocities) {
        ecs.velocities[i] = save.velocities[i]
    }


    // ========================================================
    // RUNTIME SYSTEMS
    // ========================================================

    // Physics and geometry are intentionally NOT restored yet.
    //
    // Later:
    //
    // 1. Load persistent physics description.
    // 2. Reconstruct Box3D bodies/shapes.
    // 3. Rebuild geometry from Geometry_Save_State.
    //
    // Runtime handles such as b3.BodyId must never be loaded
    // directly from the save file.


    // ========================================================
    // COMPLETE
    // ========================================================

    fmt.println("[LOAD] World successfully restored.")

    return true
}
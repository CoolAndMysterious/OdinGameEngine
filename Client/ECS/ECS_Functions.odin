package ECS


create_world :: proc(initial_capacity: int = 1024) -> World {
    assert(initial_capacity >= 0, "Invalid initial entity capacity")

    world := World{}

    world.entity_capacity = initial_capacity

    resize(&world.entity_state, initial_capacity)
    resize(&world.tags, initial_capacity)

    resize(&world.positions, initial_capacity)
    resize(&world.rotations, initial_capacity)
    resize(&world.velocities, initial_capacity)

    return world
}

destroy_world :: proc(world: ^World) {
    delete(world.entity_state)
    delete(world.free_entities)

    delete(world.tags)

    delete(world.positions)
    delete(world.rotations)
    delete(world.velocities)
}


grow_entity_storage :: proc(world: ^World) {
    old_capacity := world.entity_capacity

    new_capacity: int

    if old_capacity == 0 {
        new_capacity = 1024
    } else {
        new_capacity = old_capacity * 2
    }

    resize(&world.entity_state, new_capacity)
    resize(&world.tags, new_capacity)

    resize(&world.positions, new_capacity)
    resize(&world.rotations, new_capacity)
    resize(&world.velocities, new_capacity)

    world.entity_capacity = new_capacity
}

create_entity :: proc(world: ^World) -> Entity {
    entity: Entity

    // Reuse a destroyed entity ID first.
    if len(world.free_entities) > 0 {
        entity = pop(&world.free_entities)

        id := int(entity)

        world.entity_state[id] = .Alive
        world.tags[id] = {}

        return entity
    }

    // Create a completely new entity ID.
    entity = world.next_entity
    world.next_entity += 1

    id := int(entity)

    // We have exhausted the current storage.
    if id >= world.entity_capacity {
        grow_entity_storage(world)
    }

    world.entity_state[id] = .Alive
    world.tags[id] = {}

    return entity
}

destroy_entity :: proc(world: ^World, entity: Entity) {
    id := int(entity)

    assert(
        id >= 0 && id < len(world.entity_state),
        "Invalid entity ID",
    )

    assert(
        world.entity_state[id] == .Alive,
        "Entity is already dead",
    )

    // Mark entity as dead.
    world.entity_state[id] = .Dead

    // Remove every tag from this entity.
    world.tags[id] = {}

    // Component data is intentionally left alone.
    //
    // The component slots are simply unused while this
    // entity ID is dead. If the ID is reused later,
    // whatever components the new entity uses will
    // overwrite those slots.

    // Make the ID available for reuse.
    append(&world.free_entities, entity)
}


add_tag :: proc(world: ^World, entity: Entity, tag: Tag) {
    id := int(entity)

    assert(
        id >= 0 && id < len(world.entity_state),
        "Invalid entity ID",
    )

    assert(
        world.entity_state[id] == .Alive,
        "Entity is dead",
    )

    world.tags[id] += {tag}
}

remove_tag :: proc(world: ^World, entity: Entity, tag: Tag) {
    id := int(entity)

    assert(
        id >= 0 && id < len(world.entity_state),
        "Invalid entity ID",
    )

    assert(
        world.entity_state[id] == .Alive,
        "Entity is dead",
    )

    world.tags[id] -= {tag}
}

has_tag :: proc(world: ^World, entity: Entity, tag: Tag) -> bool {
    id := int(entity)

    if id < 0 || id >= len(world.entity_state) {
        return false
    }

    if world.entity_state[id] != .Alive {
        return false
    }

    return tag in world.tags[id]
}
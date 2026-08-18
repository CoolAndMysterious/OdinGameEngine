package ECS

create_entity :: proc(world: ^World, tags: ..Tag) -> Entity {
    entity: Entity

    // Reuse a previously destroyed entity ID first.
    if len(world.free_entities) > 0 {
        entity = pop(&world.free_entities)

        world.entity_state[int(entity)] = Entity_State.Alive
    } else {
        // Create a completely new entity ID.
        entity = world.next_entity
        world.next_entity += 1

        append(&world.entity_state, Entity_State.Alive)
    }

    // Add the requested tags.
    for tag in tags {
        add_tag(world, entity, tag)
    }

    return entity
}

destroy_entity :: proc(world: ^World, entity: Entity) {
    id := int(entity)

    assert(id >= 0 && id < len(world.entity_state), "Invalid entity ID")
    assert(world.entity_state[id] == Entity_State.Alive, "Entity is already dead")

    // Remove the entity from every tag set.
    for tag in Tag {
        remove_tag(world, entity, tag)
    }

    // Component removal will be added here once component
    // sparse sets are implemented.
    //
    // remove_position(world, entity)
    // remove_rotation(world, entity)
    // remove_velocity(world, entity)

    // The entity is now completely removed from the ECS.
    world.entity_state[id] = Entity_State.Dead

    // Make the ID available for reuse.
    append(&world.free_entities, entity)
}


is_alive :: proc(world: ^World, entity: Entity) -> bool {
    id := int(entity)

    if id < 0 || id >= len(world.entity_state) {
        return false
    }

    return world.entity_state[id] == .Alive
}

add_tag :: proc(world: ^World, entity: Entity, tag: Tag) {

    entity_index := int(entity)
    tag_set := &world.tags[tag]

    assert( entity_index >= 0 && entity_index < len(world.entity_state), "Invalid entity", )
    assert( world.entity_state[entity_index] == .Alive, "Cannot add tag to dead entity", )

    // Make sure the sparse array can be indexed by this entity.
    if entity_index >= len(tag_set.sparse) {
        old_length := len(tag_set.sparse)
        resize(&tag_set.sparse, entity_index + 1)

        // -1 means the entity is not in this set.
        for i in old_length ..< len(tag_set.sparse) {
            tag_set.sparse[i] = -1
        }
    }

    // Already has this tag.
    if tag_set.sparse[entity_index] != -1 {
        return
    }

    dense_index := len(tag_set.dense)
    append(&tag_set.dense, entity)
    tag_set.sparse[entity_index] = dense_index
}

has_tag :: proc(world: ^World, entity: Entity, tag: Tag) -> bool {
    entity_index := int(entity)
    tag_set := &world.tags[tag]

    if entity_index < 0 || entity_index >= len(tag_set.sparse) {
        return false
    }

    dense_index := tag_set.sparse[entity_index]

    if dense_index == -1 {
        return false
    }

    return tag_set.dense[dense_index] == entity
}

remove_tag :: proc(world: ^World, entity: Entity, tag: Tag) {
    entity_index := int(entity)
    tag_set := &world.tags[tag]

    if entity_index < 0 || entity_index >= len(tag_set.sparse) {
        return
    }

    dense_index := tag_set.sparse[entity_index]

    if dense_index == -1 {
        return
    }

    // Entity being removed.
    assert(tag_set.dense[dense_index] == entity)

    // Get the last entity in the dense array.
    last_index := len(tag_set.dense) - 1
    last_entity := tag_set.dense[last_index]

    // If we're not removing the last element,
    // move the last entity into the removed slot.
    if dense_index != last_index {
        tag_set.dense[dense_index] = last_entity

        // Update the moved entity's sparse index.
        tag_set.sparse[int(last_entity)] = dense_index
    }

    // Remove the final dense element.
    pop(&tag_set.dense)

    // Mark the removed entity as absent.
    tag_set.sparse[entity_index] = -1
}


add_component :: proc(
    storage: ^Component_Set($T),
    entity: Entity,
    component: T,
) {
    entity_index := int(entity)

    assert(entity_index >= 0, "Invalid entity")

    // Make sure the sparse array can represent this entity.
    if entity_index >= len(storage.sparse) {
        old_length := len(storage.sparse)

        resize(&storage.sparse, entity_index + 1)

        // -1 means the entity does not have this component.
        for i in old_length ..< len(storage.sparse) {
            storage.sparse[i] = -1
        }
    }

    // Entity already has this component.
    if storage.sparse[entity_index] != -1 {
        dense_index := storage.sparse[entity_index]

        // Replace the existing component.
        storage.data[dense_index] = component

        return
    }

    // Add new component.
    dense_index := len(storage.dense)

    append(&storage.dense, entity)
    append(&storage.data, component)

    storage.sparse[entity_index] = dense_index
}


has_component :: proc(
    storage: ^Component_Set($T),
    entity: Entity,
) -> bool {
    entity_index := int(entity)

    if entity_index < 0 || entity_index >= len(storage.sparse) {
        return false
    }

    dense_index := storage.sparse[entity_index]

    if dense_index < 0 || dense_index >= len(storage.dense) {
        return false
    }

    return storage.dense[dense_index] == entity
}


get_component :: proc(
    storage: ^Component_Set($T),
    entity: Entity,
) -> ^T {
    entity_index := int(entity)

    assert(
        entity_index >= 0 &&
        entity_index < len(storage.sparse),
        "Entity does not have this component",
    )

    dense_index := storage.sparse[entity_index]

    assert(
        dense_index >= 0 &&
        dense_index < len(storage.dense),
        "Entity does not have this component",
    )

    assert(
        storage.dense[dense_index] == entity,
        "Entity does not have this component",
    )

    return &storage.data[dense_index]
}


remove_component :: proc(
    storage: ^Component_Set($T),
    entity: Entity,
) {
    entity_index := int(entity)

    if entity_index < 0 || entity_index >= len(storage.sparse) {
        return
    }

    dense_index := storage.sparse[entity_index]

    if dense_index < 0 {
        return
    }

    assert(storage.dense[dense_index] == entity)

    last_index := len(storage.dense) - 1

    if dense_index != last_index {
        last_entity := storage.dense[last_index]

        storage.dense[dense_index] = last_entity
        storage.data[dense_index] = storage.data[last_index]

        storage.sparse[int(last_entity)] = dense_index
    }

    pop(&storage.dense)
    pop(&storage.data)

    storage.sparse[entity_index] = -1
}
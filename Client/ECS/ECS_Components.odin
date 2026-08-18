package ECS


Entity :: distinct u32
Entity_State :: enum {
    Dead,
    Alive,
}


Tag :: enum {
    Object,
    Player,
    Human,
    AI,
    Monster,
}
Tag_Set :: struct {
    sparse: [dynamic]int,
    dense:  [dynamic]Entity,
}


Position :: struct {
    x, y, z: f32,
}
Rotation :: struct {
    x, y, z, w: f32,
}
Velocity :: struct {
    x, y, z: f32,
}

Component_Set :: struct($T: typeid) {
    sparse: [dynamic]int,
    dense:  [dynamic]Entity,
    data:   #soa[dynamic]T,
}

World :: struct {
    // Entity state is indexed by Entity.
    // entity_state[entity] tells us whether the entity exists.
    entity_state: [dynamic]Entity_State,

    // Destroyed IDs that can be reused.
    free_entities: [dynamic]Entity,

    // Next never-before-used entity ID.
    next_entity: Entity,

    // One tag set for every hardcoded Tag.
    tags: [Tag]Tag_Set,

    // Components.
    positions: Component_Set(Position),
    rotations: Component_Set(Rotation),
    velocities: Component_Set(Velocity),
}
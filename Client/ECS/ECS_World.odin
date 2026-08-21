package ECS
ECS_World :: struct {

    entity_state: [dynamic]Entity_State,
    free_entities: [dynamic]Entity,
    next_entity: Entity,

    entity_capacity: int,
    
    tags: [dynamic]Tag_Bits,

    positions: #soa[dynamic]Position,
    rotations: #soa[dynamic]Rotation,
    velocities: #soa[dynamic]Velocity,
}


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
Tag_Bits :: bit_set[Tag]


Position :: struct {
    x, y, z: f32,
}
Rotation :: struct {
    x, y, z, w: f32,
}
Velocity :: struct {
    x, y, z: f32,
}
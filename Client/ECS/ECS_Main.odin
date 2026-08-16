package ECS

import Flecs "../../Shared/Flecs"
import "core:fmt"



Position :: struct {
    x, y, z: f32,
}

Rotation :: struct {
    x, y, z, w: f32,
}

Velocity :: struct {
    x, y, z: f32,
}

EntityType :: enum u8 {
    Object,
    AI,
    Human,
    Player,
}
Input :: struct{
    inputs : u32
}

Player_ID:: struct {
    player_id : u32
}
InputHistory :: struct {
    player_id:  []Player_ID,

    inputs:     []Input,
    positions:  []Position,
    rotations:  []Rotation,
    velocities: []Velocity,
}




EntityPacket :: struct {
    entity: Flecs.ecs_entity_t,
}


Create_Entity_Packet :: proc(entity: Flecs.ecs_entity_t) -> EntityPacket {
    return EntityPacket{
        entity = entity,
    }
}
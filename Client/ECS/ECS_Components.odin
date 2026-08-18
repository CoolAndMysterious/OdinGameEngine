package ECS

import "core:fmt"


World :: struct {
    entities: [dynamic]Entity,

    positions: #soa[dynamic]Position,
    rotations: #soa[dynamic]Rotation,
    velocities: #soa[dynamic]Velocity,
}


Entity :: distinct u32

Position :: struct {
    x, y, z: f32,
}

Rotation :: struct {
    x, y, z, w: f32,
}

Velocity :: struct {
    x, y, z: f32,
}
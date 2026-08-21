package ECS

import "core:fmt"
import b3 "vendor:box3d"



create_physics_world :: proc() -> Physics_World {
    physics := Physics_World{}

    world_def := b3.DefaultWorldDef()
    physics.box_world = b3.CreateWorld(world_def)

    return physics
}


destroy_physics_world :: proc(physics: ^Physics_World) {
    if b3.World_IsValid(physics.box_world) {
        b3.DestroyWorld(physics.box_world)
    }

    delete(physics.bodies)

    physics.box_world = b3.nullWorldId
}
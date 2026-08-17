package ECS

import Flecs "../../Shared/Flecs"
import b3 "vendor:box3d"


Create_Object :: proc( world: ^Flecs.ecs_world_t, registry: ECS_Registry, physics_world: b3.WorldId, ) -> Flecs.ecs_entity_t {

    // ----------------------------------------
    // Flecs entity
    // ----------------------------------------

    object := Flecs.ecs_new(world)

    position := Position{ x = 0, y = 0, z = 0, }

    rotation := Rotation{ x = 0, y = 0, z = 0, w = 1, }

    velocity := Velocity{ x = 0, y = 0, z = 0, }
    // ----------------------------------------
    // Box3D body
    // ----------------------------------------

    body_def := b3.DefaultBodyDef()

    body_def.type = .dynamicBody
    body_def.position = b3.Vec3{ position.x, position.y, position.z, }
    body := b3.CreateBody( physics_world, body_def, )


    // ----------------------------------------
    // Box3D shape
    // ----------------------------------------

    box := b3.MakeCubeHull(1.0)

    shape_def := b3.DefaultShapeDef()

    shape_def.density = 1.0
    shape_def.baseMaterial.friction = 0.3

    shape := b3.CreateHullShape( body, shape_def, &box.base, )

    // ----------------------------------------
    // Link Box3D body to Flecs
    // ----------------------------------------

    physics_body := Physics_Body{
        body = body,
    }


    // ----------------------------------------
    // Flecs components
    // ----------------------------------------

    Flecs.ecs_set_id( world, object, registry.components.position, size_of(Position), rawptr(&position), )
    Flecs.ecs_set_id( world, object, registry.components.rotation, size_of(Rotation), rawptr(&rotation), )
    Flecs.ecs_set_id( world, object, registry.components.velocity, size_of(Velocity), rawptr(&velocity), )
    Flecs.ecs_set_id( world, object, registry.components.physics_body, size_of(Physics_Body), rawptr(&physics_body), )


    // ----------------------------------------
    // Object tag
    // ----------------------------------------

    Flecs.ecs_add_id( world, object, registry.tags.object, )


    return object
}
package ECS

import Flecs "../../Shared/Flecs"
import "vendor:box3d"
import rl "vendor:raylib"


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

Physics_Body :: struct {
    body: box3d.BodyId,
}

Render_Model :: struct {
    model: rl.Model,
}

Model_Asset :: struct {
    path: string,
}


Vec3 :: struct { x, y, z: f32, }
Vec2 :: struct { x, y: f32, }
Geometry :: struct {
    vertices: [dynamic]Vec3,
    indices:  [dynamic]u32,

    normals:  [dynamic]Vec3,
    uvs:      [dynamic]Vec2,
}


ECS_Components :: struct {
    position:       Flecs.ecs_entity_t,
    rotation:       Flecs.ecs_entity_t,
    velocity:       Flecs.ecs_entity_t,
    input:          Flecs.ecs_entity_t,
    player_id:      Flecs.ecs_entity_t,
    model_asset:    Flecs.ecs_entity_t,
    Geometry:       Flecs.ecs_entity_t,

    //runtime
    physics_body: Flecs.ecs_entity_t,
    render_model: Flecs.ecs_entity_t,
}

ECS_Tags :: struct {
    object: Flecs.ecs_entity_t,
    ai: Flecs.ecs_entity_t,
    human: Flecs.ecs_entity_t,
    player: Flecs.ecs_entity_t,
    monster: Flecs.ecs_entity_t,
}

ECS_Registry :: struct {
    components: ECS_Components,
    tags: ECS_Tags,
}

Register_ECS_Components :: proc(world: ^Flecs.ecs_world_t) -> ECS_Components {

    components := ECS_Components{}

    // Position
    components.position = Flecs.ecs_struct_init(
        world,
        &Flecs.ecs_struct_desc_t{
            entity = Flecs.ecs_entity_init(
                world,
                &Flecs.ecs_entity_desc_t{
                    name = "Position",
                },
            ),

            members = {
                0 = {name = "x", type = Flecs.ecs_f32_id},
                1 = {name = "y", type = Flecs.ecs_f32_id},
                2 = {name = "z", type = Flecs.ecs_f32_id},
            },
        },
    )

    // Rotation
    components.rotation = Flecs.ecs_struct_init(
        world,
        &Flecs.ecs_struct_desc_t{
            entity = Flecs.ecs_entity_init(
                world,
                &Flecs.ecs_entity_desc_t{
                    name = "Rotation",
                },
            ),

            members = {
                0 = {name = "x", type = Flecs.ecs_f32_id},
                1 = {name = "y", type = Flecs.ecs_f32_id},
                2 = {name = "z", type = Flecs.ecs_f32_id},
                3 = {name = "w", type = Flecs.ecs_f32_id},
            },
        },
    )

    // Velocity
    components.velocity = Flecs.ecs_struct_init(
        world,
        &Flecs.ecs_struct_desc_t{
            entity = Flecs.ecs_entity_init(
                world,
                &Flecs.ecs_entity_desc_t{
                    name = "Velocity",
                },
            ),

            members = {
                0 = {name = "x", type = Flecs.ecs_f32_id},
                1 = {name = "y", type = Flecs.ecs_f32_id},
                2 = {name = "z", type = Flecs.ecs_f32_id},
            },
        },
    )

    // Input
    components.input = Flecs.ecs_struct_init(
        world,
        &Flecs.ecs_struct_desc_t{
            entity = Flecs.ecs_entity_init(
                world,
                &Flecs.ecs_entity_desc_t{
                    name = "Input",
                },
            ),

            members = {
                0 = {name = "inputs", type = Flecs.ecs_u32_id},
            },
        },
    )

    // Player ID
    components.player_id = Flecs.ecs_struct_init(
        world,
        &Flecs.ecs_struct_desc_t{
            entity = Flecs.ecs_entity_init(
                world,
                &Flecs.ecs_entity_desc_t{
                    name = "Player_ID",
                },
            ),

            members = {
                0 = {name = "player_id", type = Flecs.ecs_u32_id},
            },
        },
    )

    return components
}


Register_ECS_Tags :: proc( world: ^Flecs.ecs_world_t, ) -> ECS_Tags {

    tags := ECS_Tags{}

    tags.object = Flecs.ecs_entity_init( world, &Flecs.ecs_entity_desc_t{ name = "Object", }, )

    tags.ai = Flecs.ecs_entity_init( world, &Flecs.ecs_entity_desc_t{ name = "AI", }, )

    tags.human = Flecs.ecs_entity_init( world, &Flecs.ecs_entity_desc_t{ name = "Human", } )

    tags.player = Flecs.ecs_entity_init( world, &Flecs.ecs_entity_desc_t{ name = "Player", }, )

    tags.monster = Flecs.ecs_entity_init( world, &Flecs.ecs_entity_desc_t{ name = "Monster", }, )

    return tags
}
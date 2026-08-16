package ECS

import Flecs "../../Shared/Flecs"
import "core:fmt"
import "core:os"
import "core:strings"

Create_Player :: proc(world: ^Flecs.ecs_world_t, registry: ECS_Registry, id: u32) -> Flecs.ecs_entity_t {

    player := Flecs.ecs_new(world)

    position := Position{x = 0, y = 0, z = 0}
    rotation := Rotation{ x = 0, y = 0, z = 0, w = 1, }
    velocity := Velocity{ x = 0, y = 0, z = 0, }
    input := Input{ inputs = 0, }
    player_id := Player_ID{ player_id = id, }

    Flecs.ecs_set_id( world, player, registry.components.position, size_of(Position), rawptr(&position), )
    Flecs.ecs_set_id( world, player, registry.components.rotation, size_of(Rotation), rawptr(&rotation), )
    Flecs.ecs_set_id( world, player, registry.components.velocity, size_of(Velocity), rawptr(&velocity), )
    Flecs.ecs_set_id( world, player, registry.components.input, size_of(Input), rawptr(&input), )
    Flecs.ecs_set_id(world, player, registry.components.player_id, size_of(Player_ID), rawptr(&player_id))
    Flecs.ecs_add_id( world, player, registry.tags.player)

    return player
}


Save_Player :: proc( world: ^Flecs.ecs_world_t, player: Flecs.ecs_entity_t, ) {

    desc := Flecs.ecs_entity_to_json_desc_t{
        serialize_entity_id = true,
        serialize_values    = true,
    }

    json := Flecs.ecs_entity_to_json( world, player, &desc, )

    if json == nil {
        fmt.println("Failed to serialize player")
        return
    }

    err := os.write_entire_file_from_string(
        "player.json",
        string(json),
    )

    if err != nil {
        fmt.println("Failed to save player:", err)
        return
    }

    fmt.println("Player saved to player.json")

    // Important: Flecs allocated the returned JSON string.
    Flecs.ecs_os_api.free_(rawptr(json))
}


Load_Player :: proc( world: ^Flecs.ecs_world_t, json: string, ) -> Flecs.ecs_entity_t {

    player := Flecs.ecs_new(world)

    json_cstring := strings.clone_to_cstring(json)
    result := Flecs.ecs_entity_from_json( world, player, json_cstring, nil, )

    if result == nil {
        fmt.println("Failed to load player")
        return 0
    }

    fmt.println("Player loaded!")

    return player
}
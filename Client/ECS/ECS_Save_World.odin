package ECS

import Flecs "../../Shared/Flecs"
import "core:fmt"
import "core:os"


Save_World :: proc( world: ^Flecs.ecs_world_t, ) {

    os.make_directory_all("saves")
    json := Flecs.ecs_world_to_json(world, nil)

    if json == nil {
        fmt.println("Failed to serialize ECS world")
        return
    }

    err := os.write_entire_file_from_string( "saves/world.json", string(json), )

    if err != nil {
        fmt.println("Failed to save ECS world:", err)
        Flecs.ecs_os_api.free_(rawptr(json))
        return
    }

    Flecs.ecs_os_api.free_(rawptr(json))
    fmt.println("World saved to saves/world.json")
}
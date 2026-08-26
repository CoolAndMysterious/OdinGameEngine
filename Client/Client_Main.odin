package main

import "core:fmt"
import "vendor:ENet"
import r "renderer"
import rl "vendor:raylib"
import b3 "vendor:box3d"
import net "Network"
import "core:thread"
import physics "Physics"
import "core:os"
import ecs "ECS"

main :: proc() {

    fmt.print("Starting Game Client")

    rl.InitWindow(1280, 720, "RayLib Engine")
    rl.DisableCursor()
    defer rl.CloseWindow()

    //gridworld := ecs.create_world_grid()
    gridworld, success:= ecs.load_grid_world()
    if !success {
        fmt.println("Failed to load grid world, creating new world.")
        gridworld = ecs.create_world_grid()
    }

    for coord, chunk in gridworld.chunks {
        fmt.println("Chunk:", coord)
    }

    material := rl.LoadMaterialDefault()


    thread.create_and_start(net.network_update)

    for !rl.WindowShouldClose(){


        r.RLrender()
    }

    ecs.save_grid_world(gridworld)
}
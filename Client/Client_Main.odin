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

    grid := ecs.create_world_grid({0, 0, 0})

    ecs.add_sphere_terrain(&grid, {0, 0, 0}, 10, ecs.World_Grid_Value{density = 1.0, material = .Dirt})

    material := rl.LoadMaterialDefault()


    thread.create_and_start(net.network_update)

    for !rl.WindowShouldClose(){


        r.RLrender()
    }
}
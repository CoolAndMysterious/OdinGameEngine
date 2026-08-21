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


    grid := ecs.create_grid_3d(64)
    ecs.fill_test_cube(&grid)
    surface_mesh := ecs.generate_surface_nets(&grid)
    ray_mesh := ecs.surface_nets_to_raylib_mesh(&surface_mesh)
    rl.UploadMesh(&ray_mesh.mesh, false)

    material := rl.LoadMaterialDefault()


    thread.create_and_start(net.network_update)

    for !rl.WindowShouldClose(){


        r.RLrender(&ray_mesh, material)
    }
}
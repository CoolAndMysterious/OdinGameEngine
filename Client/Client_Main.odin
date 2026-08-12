package main

import "core:fmt"
import "vendor:ENet"
import r "renderer"
import rl "vendor:raylib"
import b3 "vendor:box3d"
import net "Network"
import "core:thread"
import physics "Physics"

main :: proc() {

    fmt.print("Starting Game Client")

    rl.InitWindow(1280, 720, "RayLib Engine")
    rl.DisableCursor()
    defer rl.CloseWindow()

    world := physics.CreateWorld()
    defer physics.DestroyWorld(world)
    fmt.print(world.index1)


    cube := physics.CreateCube(world,{0, 5, 0},1.0,rl.RED,)

    thread.create_and_start(net.network_update)

    //rl.SetTargetFPS(30)
    dt := rl.GetFrameTime()

    physics_dt: f32 = 1.0 / 60.0
    accumulator: f32 = 0.0

    for !rl.WindowShouldClose(){



        dt := rl.GetFrameTime()

        if dt > 0.25 {
            dt = 0.25
        }

        accumulator += dt

        for accumulator >= physics_dt {
            b3.World_Step(
                world,
                physics_dt,
                4,
            )

            accumulator -= physics_dt
        }

        
        
        
        
        
        
        r.RLrender(&cube)

    }
}

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

    world := ecs.World{}
    ecs.create_entity(&world, .Object)

    player := ecs.create_entity( &world, .Player, .Human, .Object, )
    fmt.println("Player Entity :", player)

    ecs.add_component( &world.positions, player, ecs.Position{ x = 10, y = 20, z = 30, }, )

    ecs.add_component( &world.velocities, player, ecs.Velocity{ x = 1, y = 2, z = 3, }, )

    fmt.println("Player :", ecs.has_component(&world.positions, player))
    fmt.println("Player :", ecs.has_component(&world.velocities, player))

    player_position := ecs.get_component( &world.positions, player, )
    player_position.x += 100
    fmt.println(player_position^)
    ecs.remove_component( &world.velocities, player, )


    //Box3D PhysWorld Ini
    physics_world := physics.CreateWorld()
    defer physics.DestroyWorld(physics_world)
    fmt.print(physics_world.index1)


    cube := physics.CreateCube(physics_world,{0, 5, 0},1.0,rl.RED,)

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
                physics_world,
                physics_dt,
                4,
            )

            accumulator -= physics_dt
        }

        r.RLrender(&cube)
    }
}

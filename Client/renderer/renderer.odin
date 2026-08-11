package renderer


import "core:fmt"
import rl "vendor:raylib"
import physics "../Physics"
import b3 "vendor:box3d"


add :: proc(a:int, b:int) -> int{
    return a + b
}


camera := rl.Camera3D{
        position   = { 0, 2, 6 },
        target     = { 0, 1, 0 },
        up         = { 0, 1, 0 },
        fovy       = 45,
        projection = .PERSPECTIVE,
}


RLrender :: proc(cube: ^physics.Cube) {

    rl.BeginDrawing()
    
    rl.ClearBackground(rl.RAYWHITE)

    rl.UpdateCamera(&camera, .FREE)
    rl.BeginMode3D(camera)

    //rl.DrawCube({ 0.0, 0.5, 0.0 }, 1.0, 1.0, 1.0, rl.RED)
    //rl.DrawCubeWires({ 0.0, 0.5, 0.0 }, 1.0, 1.0, 1.0, rl.BLACK)   
    rl.DrawGrid(20, 1.0)


    physics.DrawCube(cube)   

   

    rl.EndMode3D()

    rl.DrawFPS(10, 10)

    rl.EndDrawing()
}
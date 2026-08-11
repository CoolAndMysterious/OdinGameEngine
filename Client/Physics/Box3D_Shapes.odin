package Physics

import b3 "vendor:box3d"
import rl "vendor:raylib"


Cube :: struct {
    body:  b3.BodyId,
    shape: b3.ShapeId,

    size:  f32,
    color: rl.Color,
}


CreateCube :: proc(
    world: b3.WorldId,
    position: [3]f32,
    size: f32,
    color: rl.Color,
) -> Cube {

    // ------------------------------------------------------------
    // Create Box3D body
    // ------------------------------------------------------------

    body_def := b3.DefaultBodyDef()

    body_def.type = .dynamicBody
    body_def.position = position

    body := b3.CreateBody(
        world,
        body_def,
    )


    // ------------------------------------------------------------
    // Create Box3D collision shape
    // ------------------------------------------------------------

    shape_def := b3.DefaultShapeDef()

    shape_def.density = 1.0
    shape_def.baseMaterial.friction = 0.5
    shape_def.baseMaterial.restitution = 0.2

    half_width := size * 0.5

    cube_hull := b3.MakeCubeHull(half_width)

    shape := b3.CreateHullShape(
        body,
        shape_def,
        &cube_hull.base,
    )


    // ------------------------------------------------------------
    // Return combined Raylib + Box3D cube
    // ------------------------------------------------------------

    return Cube {
        body  = body,
        shape = shape,

        size  = size,
        color = color,
    }
}


DrawCube :: proc(cube: ^Cube) {
    position := b3.Body_GetPosition(cube.body)

    rl.DrawCubeV(
        position,
        {cube.size, cube.size, cube.size},
        cube.color,
    )

    rl.DrawCubeWiresV(
        position,
        {cube.size, cube.size, cube.size},
        rl.BLACK,
    )
}
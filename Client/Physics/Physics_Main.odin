package Physics

import "core:fmt"
import b3 "vendor:box3d"

CreateWorld :: proc() -> b3.WorldId {
    def := b3.DefaultWorldDef()

    def.gravity = {0, -9.81, 0}
    def.workerCount = 1
    return b3.CreateWorld(def)
}

DestroyWorld :: proc(world: b3.WorldId) {
    b3.DestroyWorld(world)
}

Phys_Object :: struct {
    id:        u64,
    position:  [3]f32,
    rotation:  [4]f32,
    velocity:  [3]f32,

    half_size: [3]f32,
}

Phys_World :: struct {
    id:       u32,
    gravity:  [3]f32,
    objects:  [dynamic]Phys_Object,
}
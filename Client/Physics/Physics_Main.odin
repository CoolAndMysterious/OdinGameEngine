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


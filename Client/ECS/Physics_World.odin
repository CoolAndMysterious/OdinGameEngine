package ECS
import b3 "vendor:box3d"


Physics_World :: struct {
    box_world: b3.WorldId,

    bodies: #soa[dynamic]Physics_Body
}


Physics_Body :: struct {
    box_body: b3.BodyId,
}
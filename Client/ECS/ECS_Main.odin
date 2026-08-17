package ECS

import Flecs "../../Shared/Flecs"


EntityPacket :: struct {
    entity: Flecs.ecs_entity_t,
}


Create_Entity_Packet :: proc(entity: Flecs.ecs_entity_t) -> EntityPacket {
    return EntityPacket{
        entity = entity,
    }
}
package Network

import "core:fmt"
import "vendor:ENet"
import Flecs "../../Shared/Flecs"



EntityData :: struct {
    entity_type: EntityType,
}


EntityType :: enum u8 {
    Object,
    AI,
    Human,
    Player,
}

EntityPacket :: struct {
    entity: Flecs.ecs_entity_t,
}


Create_Entity_Packet :: proc(entity: Flecs.ecs_entity_t) -> EntityPacket {
    return EntityPacket{
        entity = entity,
    }
}
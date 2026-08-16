package main

import "core:fmt"
import "core:thread"
import net "Network"
import Flecs "../Shared/Flecs"
import "vendor:ENet"


main :: proc() {
    fmt.println("Hello, World!")
    world := Flecs.ecs_init()
    defer Flecs.ecs_fini(world)

    Tags :: struct {
        Player: Flecs.ecs_entity_t,
        AI:     Flecs.ecs_entity_t,
        Human:  Flecs.ecs_entity_t,
        Object: Flecs.ecs_entity_t,
    }
    create_tags :: proc(world: ^Flecs.ecs_world_t) -> Tags {
        return Tags{
            Player = Flecs.ecs_new(world),
            AI     = Flecs.ecs_new(world),
            Human  = Flecs.ecs_new(world),
            Object = Flecs.ecs_new(world),
        }
    }

    tags := create_tags(world)

    entity := Flecs.ecs_new(world)
    Flecs.ecs_add_id(world, entity, tags.Player)

    packet_data := net.EntityPacket{
        entity = entity,
    }

    thread.create_and_start(net.network_update)
    //net.network_update()

    packet := ENet.packet_create(
        rawptr(&packet_data),
        size_of(packet_data),
        {.RELIABLE},
    )
    event: ENet.Event
    ENet.peer_send(
        event.peer,
        0,
        packet,
    )
}
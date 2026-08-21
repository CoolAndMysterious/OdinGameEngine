package main

import "core:fmt"

import ecs "../Client/ECS"


main :: proc() {

    fmt.println()
    fmt.println("================================================")
    fmt.println("              ECS SAVE / LOAD TEST")
    fmt.println("================================================")
    fmt.println()


    // ========================================================
    // CREATE ORIGINAL WORLD
    // ========================================================

    world := ecs.create_world(16)

    fmt.println("Initial world created.")
    fmt.println("Capacity:", world.entity_capacity)
    fmt.println()


    // ========================================================
    // CREATE ENTITIES
    // ========================================================

    entity_0 := ecs.create_entity(&world)
    entity_1 := ecs.create_entity(&world)
    entity_2 := ecs.create_entity(&world)
    entity_3 := ecs.create_entity(&world)
    entity_4 := ecs.create_entity(&world)
    entity_5 := ecs.create_entity(&world)

    fmt.println("Created 6 entities.")
    fmt.println()


    // ========================================================
    // ADD TAGS
    // ========================================================

    // Entity 0:
    // Player + Human + Object

    ecs.add_tag(&world, entity_0, .Player)
    ecs.add_tag(&world, entity_0, .Human)
    ecs.add_tag(&world, entity_0, .Object)


    // Entity 1:
    // Monster + AI + Object

    ecs.add_tag(&world, entity_1, .Monster)
    ecs.add_tag(&world, entity_1, .AI)
    ecs.add_tag(&world, entity_1, .Object)


    // Entity 2:
    // Human + Object

    ecs.add_tag(&world, entity_2, .Human)
    ecs.add_tag(&world, entity_2, .Object)


    // Entity 3:
    // Player + Object

    ecs.add_tag(&world, entity_3, .Player)
    ecs.add_tag(&world, entity_3, .Object)


    // Entity 4:
    // Monster

    ecs.add_tag(&world, entity_4, .Monster)


    // Entity 5:
    // AI

    ecs.add_tag(&world, entity_5, .AI)


    // ========================================================
    // WRITE COMPONENT DATA
    // ========================================================

    for i in 0 ..< 6 {

        world.positions[i] = ecs.Position{
            x = f32(i) * 10.0,
            y = f32(i) * 20.0,
            z = f32(i) * 30.0,
        }

        world.rotations[i] = ecs.Rotation{
            x = f32(i),
            y = f32(i) * 2.0,
            z = f32(i) * 3.0,
            w = 1.0,
        }

        world.velocities[i] = ecs.Velocity{
            x = f32(i) + 0.1,
            y = f32(i) + 0.2,
            z = f32(i) + 0.3,
        }
    }


    // ========================================================
    // DESTROY ENTITIES
    // ========================================================

    ecs.destroy_entity(&world, entity_1)
    ecs.destroy_entity(&world, entity_4)

    fmt.println("Destroyed Entity 1 and Entity 4.")
    fmt.println("Free IDs:", world.free_entities)
    fmt.println()


    // ========================================================
    // WRITE DATA INTO DEAD ENTITY
    // ========================================================
    //
    // We intentionally put data into a DEAD slot.
    //
    // Your requirement is that the entire world is saved,
    // including dead/unused component slots.
    //

    world.positions[int(entity_1)] = ecs.Position{
        x = 1111.0,
        y = 2222.0,
        z = 3333.0,
    }

    world.rotations[int(entity_1)] = ecs.Rotation{
        x = 4444.0,
        y = 5555.0,
        z = 6666.0,
        w = 7777.0,
    }

    world.velocities[int(entity_1)] = ecs.Velocity{
        x = 8888.0,
        y = 9999.0,
        z = 11111.0,
    }


    // ========================================================
    // SAVE
    // ========================================================

    fmt.println("Saving world...")

    if !ecs.save_world(&world) {

        fmt.println("FAIL: Could not save world.")

        ecs.destroy_world(&world)

        return
    }

    fmt.println("PASS: World saved.")
    fmt.println("Path: saves/world_save.cbor")
    fmt.println()


    // ========================================================
    // DESTROY ORIGINAL WORLD
    // ========================================================
    //
    // We are now going to completely get rid of the runtime
    // world that was used to create the save.
    //

    ecs.destroy_world(&world)


    // ========================================================
    // CREATE A COMPLETELY DIFFERENT WORLD
    // ========================================================
    //
    // The original world had capacity 16.
    //
    // This world only has capacity 2.
    //
    // load_world() must rebuild it into the saved world.
    //

    world = ecs.create_world(2)

    defer ecs.destroy_world(&world)

    fmt.println("Created replacement runtime world.")
    fmt.println("Capacity before load:", world.entity_capacity)
    fmt.println()


    // ========================================================
    // LOAD
    // ========================================================

    fmt.println("Loading world...")

    if !ecs.load_world(&world) {

        fmt.println("FAIL: Could not load world.")

        return
    }

    fmt.println("PASS: World loaded.")
    fmt.println("Capacity after load:", world.entity_capacity)
    fmt.println()


    // ========================================================
    // VALIDATION
    // ========================================================

    passed := true


    // ========================================================
    // CAPACITY
    // ========================================================

    if world.entity_capacity != 16 {

        fmt.println(
            "FAIL: entity_capacity",
            "Expected:", 16,
            "Got:", world.entity_capacity,
        )

        passed = false

    } else {

        fmt.println("PASS: entity_capacity")
    }


    // ========================================================
    // NEXT ENTITY
    // ========================================================

    if world.next_entity != ecs.Entity(6) {

        fmt.println(
            "FAIL: next_entity",
            "Expected:", ecs.Entity(6),
            "Got:", world.next_entity,
        )

        passed = false

    } else {

        fmt.println("PASS: next_entity")
    }


    // ========================================================
    // ENTITY STATES
    // ========================================================

    expected_states: [6]ecs.Entity_State = {
        .Alive,
        .Dead,
        .Alive,
        .Alive,
        .Dead,
        .Alive,
    }

    state_test := true

    for i in 0 ..< 6 {

        if world.entity_state[i] != expected_states[i] {

            fmt.println(
                "FAIL: entity_state[",
                i,
                "]",
                "Expected:",
                expected_states[i],
                "Got:",
                world.entity_state[i],
            )

            state_test = false
            passed = false
        }
    }

    if state_test {
        fmt.println("PASS: entity_state")
    }


    // ========================================================
    // FREE ENTITY IDs
    // ========================================================

    free_test := true

    if len(world.free_entities) != 2 {

        fmt.println(
            "FAIL: free_entities length",
            "Expected:", 2,
            "Got:", len(world.free_entities),
        )

        free_test = false

    } else {

        if world.free_entities[0] != entity_1 {

            fmt.println(
                "FAIL: free_entities[0]",
                "Expected:", entity_1,
                "Got:", world.free_entities[0],
            )

            free_test = false
        }

        if world.free_entities[1] != entity_4 {

            fmt.println(
                "FAIL: free_entities[1]",
                "Expected:", entity_4,
                "Got:", world.free_entities[1],
            )

            free_test = false
        }
    }

    if free_test {

        fmt.println("PASS: free_entities")

    } else {

        passed = false
    }


    // ========================================================
    // TAGS
    // ========================================================

    tag_test := true


    // Entity 0:
    // Player + Human + Object

    if !(.Player in world.tags[0]) ||
       !(.Human in world.tags[0]) ||
       !(.Object in world.tags[0]) {

        fmt.println("FAIL: Entity 0 tags")

        tag_test = false
    }


    // Entity 1:
    // Dead -> tags should have been removed by destroy_entity.

    if card(world.tags[1]) != 0 {

        fmt.println("FAIL: Entity 1 should have no tags")

        tag_test = false
    }


    // Entity 2:
    // Human + Object

    if !(.Human in world.tags[2]) ||
       !(.Object in world.tags[2]) {

        fmt.println("FAIL: Entity 2 tags")

        tag_test = false
    }


    // Entity 3:
    // Player + Object

    if !(.Player in world.tags[3]) ||
       !(.Object in world.tags[3]) {

        fmt.println("FAIL: Entity 3 tags")

        tag_test = false
    }


    // Entity 4:
    // Dead -> no tags

    if card(world.tags[4]) != 0 {

        fmt.println("FAIL: Entity 4 should have no tags")

        tag_test = false
    }


    // Entity 5:
    // AI

    if !(.AI in world.tags[5]) {

        fmt.println("FAIL: Entity 5 tags")

        tag_test = false
    }


    if tag_test {

        fmt.println("PASS: tags")

    } else {

        passed = false
    }


    // ========================================================
    // POSITIONS
    // ========================================================

    position_test := true

    for i in 0 ..< 6 {

        expected := ecs.Position{
            x = f32(i) * 10.0,
            y = f32(i) * 20.0,
            z = f32(i) * 30.0,
        }


        // Entity 1 was dead but still had component data.

        if i == 1 {

            expected = ecs.Position{
                x = 1111.0,
                y = 2222.0,
                z = 3333.0,
            }
        }


        actual := world.positions[i]

        if actual.x != expected.x ||
           actual.y != expected.y ||
           actual.z != expected.z {

            fmt.println(
                "FAIL: positions[",
                i,
                "]",
                "Expected:",
                expected,
                "Got:",
                actual,
            )

            position_test = false
            passed = false
        }
    }

    if position_test {
        fmt.println("PASS: positions")
    }


    // ========================================================
    // ROTATIONS
    // ========================================================

    rotation_test := true

    for i in 0 ..< 6 {

        expected := ecs.Rotation{
            x = f32(i),
            y = f32(i) * 2.0,
            z = f32(i) * 3.0,
            w = 1.0,
        }


        // Entity 1 was deliberately modified while dead.

        if i == 1 {

            expected = ecs.Rotation{
                x = 4444.0,
                y = 5555.0,
                z = 6666.0,
                w = 7777.0,
            }
        }


        actual := world.rotations[i]

        if actual.x != expected.x ||
           actual.y != expected.y ||
           actual.z != expected.z ||
           actual.w != expected.w {

            fmt.println(
                "FAIL: rotations[",
                i,
                "]",
                "Expected:",
                expected,
                "Got:",
                actual,
            )

            rotation_test = false
            passed = false
        }
    }

    if rotation_test {
        fmt.println("PASS: rotations")
    }


    // ========================================================
    // VELOCITIES
    // ========================================================

    velocity_test := true

    for i in 0 ..< 6 {

        expected := ecs.Velocity{
            x = f32(i) + 0.1,
            y = f32(i) + 0.2,
            z = f32(i) + 0.3,
        }


        // Entity 1 was deliberately modified while dead.

        if i == 1 {

            expected = ecs.Velocity{
                x = 8888.0,
                y = 9999.0,
                z = 11111.0,
            }
        }


        actual := world.velocities[i]

        if actual.x != expected.x ||
           actual.y != expected.y ||
           actual.z != expected.z {

            fmt.println(
                "FAIL: velocities[",
                i,
                "]",
                "Expected:",
                expected,
                "Got:",
                actual,
            )

            velocity_test = false
            passed = false
        }
    }

    if velocity_test {
        fmt.println("PASS: velocities")
    }


    // ========================================================
    // TEST ENTITY REUSE
    // ========================================================
    //
    // The free list after loading should be:
    //
    // [1, 4]
    //
    // create_entity() pops from the end, therefore Entity 4
    // should be reused first.
    //

    reused_entity := ecs.create_entity(&world)

    if reused_entity != entity_4 {

        fmt.println(
            "FAIL: entity reuse",
            "Expected:", entity_4,
            "Got:", reused_entity,
        )

        passed = false

    } else {

        fmt.println(
            "PASS: entity reuse",
            "Reused:", reused_entity,
        )
    }


    // ========================================================
    // FINAL STATE
    // ========================================================

    fmt.println()
    fmt.println("================================================")

    fmt.println(
        "Final capacity:",
        world.entity_capacity,
    )

    fmt.println(
        "Next entity:",
        world.next_entity,
    )

    fmt.println(
        "Free IDs:",
        world.free_entities,
    )

    fmt.println()


    // ========================================================
    // FINAL RESULT
    // ========================================================

    if passed {

        fmt.println("       SAVE / LOAD TEST PASSED")
        fmt.println("       WORLD RESTORED CORRECTLY")

    } else {

        fmt.println("       SAVE / LOAD TEST FAILED")
    }

    fmt.println("================================================")
    fmt.println()
}
package main

import "core:fmt"
import "core:math"
import "core:time"

import ecs "../Client/ECS"


ENTITY_COUNT :: 1_000_000
SIMULATION_STEPS :: 20

DT :: 0.016666667


main :: proc() {
    fmt.println()
    fmt.println("============================================================")
    fmt.println("                 ECS HEAVY SIMULATION TEST")
    fmt.println("============================================================")
    fmt.println()
    fmt.println("Entities         :", ENTITY_COUNT)
    fmt.println("Simulation steps :", SIMULATION_STEPS)
    fmt.println("Delta time       :", DT)
    fmt.println()


    // ========================================================
    // WORLD
    // ========================================================

    fmt.println("Creating world...")

    world := ecs.create_world(ENTITY_COUNT)
    defer ecs.destroy_world(&world)

    fmt.println("World created.")
    fmt.println()


    // ========================================================
    // CREATE ENTITIES
    // ========================================================

    fmt.println("Creating entities...")

    start := time.tick_now()

    for i in 0 ..< ENTITY_COUNT {
        entity := ecs.create_entity(&world)

        // Every entity is an object.
        ecs.add_tag(&world, entity, .Object)

        // Split the population.
        if i % 4 == 0 {
            // Player
            ecs.add_tag(&world, entity, .Player)
            ecs.add_tag(&world, entity, .Human)

        } else if i % 4 == 1 {
            // AI monster
            ecs.add_tag(&world, entity, .Monster)
            ecs.add_tag(&world, entity, .AI)

        } else if i % 4 == 2 {
            // Human NPC
            ecs.add_tag(&world, entity, .Human)

        } else {
            // AI object
            ecs.add_tag(&world, entity, .AI)
        }


        // ----------------------------------------------------
        // Initial Position
        // ----------------------------------------------------

        id := int(entity)

        world.positions[id].x =
            f32(i % 1000) * 2.0

        world.positions[id].y =
            f32((i / 1000) % 1000) * 2.0

        world.positions[id].z =
            f32(i / 1_000_000) * 2.0


        // ----------------------------------------------------
        // Initial Velocity
        // ----------------------------------------------------

        world.velocities[id].x =
            f32((i % 17) - 8) * 0.1

        world.velocities[id].y =
            f32((i % 11) - 5) * 0.1

        world.velocities[id].z =
            f32((i % 23) - 11) * 0.1


        // ----------------------------------------------------
        // Initial Rotation
        // ----------------------------------------------------

        world.rotations[id].x = 0.0
        world.rotations[id].y = 0.0
        world.rotations[id].z = 0.0
        world.rotations[id].w = 1.0
    }

    elapsed := time.tick_since(start)

    fmt.println(
        "Entity creation:",
        time.duration_milliseconds(elapsed),
        "ms",
    )

    fmt.println()


    // ========================================================
    // SIMULATION
    // ========================================================

    fmt.println("============================================================")
    fmt.println("                    SIMULATION")
    fmt.println("============================================================")
    fmt.println()


    start = time.tick_now()


    total_checksum: f64 = 0


    for step in 0 ..< SIMULATION_STEPS {

        simulation_time := f32(step) * DT


        // ====================================================
        // PASS 1
        // Physics / movement
        // ====================================================

        for i in 0 ..< ENTITY_COUNT {

            id := i

            px := world.positions[id].x
            py := world.positions[id].y
            pz := world.positions[id].z

            vx := world.velocities[id].x
            vy := world.velocities[id].y
            vz := world.velocities[id].z


            // ------------------------------------------------
            // Gravity
            // ------------------------------------------------

            vy -= 9.81 * DT


            // ------------------------------------------------
            // Drag
            // ------------------------------------------------

            speed_squared :=
                vx * vx +
                vy * vy +
                vz * vz

            drag :=
                1.0 / (1.0 + speed_squared * 0.002)

            vx *= drag
            vy *= drag
            vz *= drag


            // ------------------------------------------------
            // Oscillating environmental force
            // ------------------------------------------------

            force_x :=
                math.sin(px * 0.01 + simulation_time)

            force_y :=
                math.cos(py * 0.013 + simulation_time * 1.7)

            force_z :=
                math.sin(pz * 0.017 + simulation_time * 0.7)


            vx += force_x * DT
            vy += force_y * DT
            vz += force_z * DT


            // ------------------------------------------------
            // Position integration
            // ------------------------------------------------

            px += vx * DT
            py += vy * DT
            pz += vz * DT


            // ------------------------------------------------
            // Soft world boundaries
            // ------------------------------------------------

            if px > 2000.0 {
                px = -2000.0
            }

            if px < -2000.0 {
                px = 2000.0
            }

            if py > 2000.0 {
                py = -2000.0
            }

            if py < -2000.0 {
                py = 2000.0
            }

            if pz > 2000.0 {
                pz = -2000.0
            }

            if pz < -2000.0 {
                pz = 2000.0
            }


            // ------------------------------------------------
            // Store
            // ------------------------------------------------

            world.positions[id].x = px
            world.positions[id].y = py
            world.positions[id].z = pz

            world.velocities[id].x = vx
            world.velocities[id].y = vy
            world.velocities[id].z = vz
        }


        // ====================================================
        // PASS 2
        // AI / gameplay calculations
        // ====================================================

        for i in 0 ..< ENTITY_COUNT {

            id := i
            entity := ecs.Entity(i)


            px := world.positions[id].x
            py := world.positions[id].y
            pz := world.positions[id].z


            // ------------------------------------------------
            // Players
            // ------------------------------------------------

            if ecs.has_tag(&world, entity, .Player) {

                // Target point changes over time.
                target_x :=
                    math.sin(simulation_time * 0.5) * 500.0

                target_y :=
                    math.cos(simulation_time * 0.7) * 300.0

                target_z :=
                    math.sin(simulation_time * 0.3) * 400.0


                dx := target_x - px
                dy := target_y - py
                dz := target_z - pz


                distance_squared :=
                    dx * dx +
                    dy * dy +
                    dz * dz


                if distance_squared > 0.001 {

                    inv_distance :=
                        1.0 / math.sqrt(distance_squared)

                    dx *= inv_distance
                    dy *= inv_distance
                    dz *= inv_distance


                    world.velocities[id].x += dx * 0.25 * DT
                    world.velocities[id].y += dy * 0.25 * DT
                    world.velocities[id].z += dz * 0.25 * DT
                }
            }


            // ------------------------------------------------
            // Monsters / AI
            // ------------------------------------------------

            if ecs.has_tag(&world, entity, .AI) {

                // Procedural AI "decision" calculation.
                threat :=
                    math.sin(px * 0.021) *
                    math.cos(pz * 0.017)

                aggression :=
                    math.sin(simulation_time * 2.0 + py * 0.01)

                decision :=
                    threat * 0.6 +
                    aggression * 0.4


                if decision > 0.25 {

                    world.velocities[id].x +=
                        math.sin(px * 0.05) * DT

                    world.velocities[id].z +=
                        math.cos(pz * 0.05) * DT

                } else {

                    world.velocities[id].x *= 0.999
                    world.velocities[id].z *= 0.999
                }
            }


            // ------------------------------------------------
            // Human entities
            // ------------------------------------------------

            if ecs.has_tag(&world, entity, .Human) {

                // Small breathing/idle movement.
                world.positions[id].y +=
                    math.sin(simulation_time * 3.0 + f32(id) * 0.001) *
                    0.01
            }
        }


        // ====================================================
        // PASS 3
        // Rotation / orientation
        // ====================================================

        for i in 0 ..< ENTITY_COUNT {

            id := i

            vx := world.velocities[id].x
            vz := world.velocities[id].z

            horizontal_speed :=
                math.sqrt(vx * vx + vz * vz)


            if horizontal_speed > 0.001 {

                heading :=
                    math.atan2(vx, vz)

                world.rotations[id].y =
                    heading
            }


            // Simple rotational animation.
            world.rotations[id].x =
                math.sin(simulation_time + f32(id) * 0.0001) * 0.1

            world.rotations[id].z =
                math.cos(simulation_time * 0.7 + f32(id) * 0.0001) * 0.1
        }


        // ====================================================
        // PASS 4
        // Expensive gameplay evaluation
        // ====================================================

        step_checksum: f64 = 0

        for i in 0 ..< ENTITY_COUNT {

            id := i

            px := world.positions[id].x
            py := world.positions[id].y
            pz := world.positions[id].z

            vx := world.velocities[id].x
            vy := world.velocities[id].y
            vz := world.velocities[id].z


            distance :=
                math.sqrt(
                    px * px +
                    py * py +
                    pz * pz,
                )


            kinetic :=
                0.5 *
                (
                    vx * vx +
                    vy * vy +
                    vz * vz
                )


            rotational_energy :=
                world.rotations[id].x *
                world.rotations[id].x +

                world.rotations[id].y *
                world.rotations[id].y +

                world.rotations[id].z *
                world.rotations[id].z


            value :=
                math.sin(distance * 0.001) *
                math.cos(kinetic * 0.01) +
                rotational_energy * 0.1


            step_checksum += f64(value)
        }


        total_checksum += step_checksum


        if step % 5 == 0 {
            fmt.println(
                "Step",
                step,
                "checksum:",
                step_checksum,
            )
        }
    }


    elapsed = time.tick_since(start)


    // ========================================================
    // RESULTS
    // ========================================================

    fmt.println()
    fmt.println("============================================================")
    fmt.println("                    RESULTS")
    fmt.println("============================================================")
    fmt.println()

    fmt.println(
        "Simulation time:",
        time.duration_milliseconds(elapsed),
        "ms",
    )

    fmt.println(
        "Simulation time:",
        time.duration_seconds(elapsed),
        "seconds",
    )

    fmt.println(
        "Steps:",
        SIMULATION_STEPS,
    )

    fmt.println(
        "Entities:",
        ENTITY_COUNT,
    )

    fmt.println(
        "Entity-steps:",
        ENTITY_COUNT * SIMULATION_STEPS,
    )

    fmt.println(
        "Total checksum:",
        total_checksum,
    )


    // ========================================================
    // FINAL SAMPLE
    // ========================================================

    fmt.println()
    fmt.println("Final entity samples:")

    for i in 0 ..< 5 {

        fmt.printf(
            "Entity %d: P=(%.3f %.3f %.3f) V=(%.3f %.3f %.3f)\n",
            i,

            world.positions[i].x,
            world.positions[i].y,
            world.positions[i].z,

            world.velocities[i].x,
            world.velocities[i].y,
            world.velocities[i].z,
        )
    }


    fmt.println()
    fmt.println("============================================================")
    fmt.println("                     TEST COMPLETE")
    fmt.println("============================================================")

    for{
        continue
    }
}
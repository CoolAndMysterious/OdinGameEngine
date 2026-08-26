package ECS

import rl "vendor:raylib"

import "core:math"


// ============================================================
// Surface Nets configuration
// ============================================================

CHUNK_ISO_LEVEL :: f32(0.0)


// ============================================================
// Public
// ============================================================

// Creates a runtime Raylib mesh from the chunk density.
//
// The returned mesh is owned by the caller.
//
// When the mesh is no longer needed:
//
//     destroy_chunk_mesh(&mesh)
//
// The Chunk itself is not modified.
create_chunk_mesh :: proc(chunk: ^Chunk) -> rl.Mesh {

    mesh := rl.Mesh{}

    cells := CHUNK_SIZE - 1


    // --------------------------------------------------------
    // Temporary Surface Nets vertex storage.
    //
    // One Surface Nets vertex can exist per cell.
    // --------------------------------------------------------

    vertices := make(
        [dynamic][3]f32,
    )
    defer delete(vertices)

    max_vertices := cells * cells * cells

    reserve(
        &vertices,
        max_vertices,
    )


    // --------------------------------------------------------
    // Every cell gets either:
    //
    //     -1  = no surface
    //     >=0 = vertex index
    // --------------------------------------------------------

    cell_vertices := make(
        [dynamic]int,
        max_vertices,
    )
    defer delete(cell_vertices)

    for i in 0..<len(cell_vertices) {
        cell_vertices[i] = -1
    }


    // ========================================================
    // PASS 1
    //
    // Find cells containing the surface.
    // ========================================================

    for z in 0..<cells {
        for y in 0..<cells {
            for x in 0..<cells {

                densities: [8]f32

                densities[0] = chunk_density(
                    chunk,
                    x,
                    y,
                    z,
                )

                densities[1] = chunk_density(
                    chunk,
                    x + 1,
                    y,
                    z,
                )

                densities[2] = chunk_density(
                    chunk,
                    x + 1,
                    y + 1,
                    z,
                )

                densities[3] = chunk_density(
                    chunk,
                    x,
                    y + 1,
                    z,
                )

                densities[4] = chunk_density(
                    chunk,
                    x,
                    y,
                    z + 1,
                )

                densities[5] = chunk_density(
                    chunk,
                    x + 1,
                    y,
                    z + 1,
                )

                densities[6] = chunk_density(
                    chunk,
                    x + 1,
                    y + 1,
                    z + 1,
                )

                densities[7] = chunk_density(
                    chunk,
                    x,
                    y + 1,
                    z + 1,
                )


                // ------------------------------------------------
                // Does this cell contain the isosurface?
                // ------------------------------------------------

                has_inside := false
                has_outside := false

                for density in densities {

                    if density >= CHUNK_ISO_LEVEL {
                        has_inside = true
                    } else {
                        has_outside = true
                    }
                }

                if !has_inside || !has_outside {
                    continue
                }


                // ------------------------------------------------
                // Cube corners.
                // ------------------------------------------------

                corners: [8][3]f32 = {
                    {0, 0, 0},
                    {1, 0, 0},
                    {1, 1, 0},
                    {0, 1, 0},

                    {0, 0, 1},
                    {1, 0, 1},
                    {1, 1, 1},
                    {0, 1, 1},
                }


                // ------------------------------------------------
                // Cube edges.
                // ------------------------------------------------

                edges: [12][2]int = {
                    {0, 1},
                    {1, 2},
                    {2, 3},
                    {3, 0},

                    {4, 5},
                    {5, 6},
                    {6, 7},
                    {7, 4},

                    {0, 4},
                    {1, 5},
                    {2, 6},
                    {3, 7},
                }


                // ------------------------------------------------
                // Find all edge crossings.
                //
                // The Surface Nets vertex is the average of
                // those crossing positions.
                // ------------------------------------------------

                position := [3]f32{}
                crossing_count := 0

                for edge in edges {

                    a := edge[0]
                    b := edge[1]

                    da := densities[a]
                    db := densities[b]


                    // No zero crossing.
                    if (da < CHUNK_ISO_LEVEL &&
                        db < CHUNK_ISO_LEVEL) ||

                       (da >= CHUNK_ISO_LEVEL &&
                        db >= CHUNK_ISO_LEVEL) {

                        continue
                    }


                    denominator := db - da

                    if abs(denominator) < 0.000001 {
                        continue
                    }


                    t := (
                        CHUNK_ISO_LEVEL - da
                    ) / denominator


                    local_position := corners[a] +
                        (corners[b] - corners[a]) * t


                    position += {
                        f32(x) + local_position.x,
                        f32(y) + local_position.y,
                        f32(z) + local_position.z,
                    }

                    crossing_count += 1
                }


                if crossing_count == 0 {
                    continue
                }


                position /= f32(crossing_count)


                // ------------------------------------------------
                // Store Surface Nets vertex.
                // ------------------------------------------------

                vertex_index := len(vertices)

                append(
                    &vertices,
                    position,
                )


                cell_index := chunk_cell_index(
                    x,
                    y,
                    z,
                )

                cell_vertices[cell_index] =
                    vertex_index
            }
        }
    }


    // ========================================================
    // No surface in the chunk.
    // ========================================================

    if len(vertices) == 0 {
        return mesh
    }


    // ========================================================
    // PASS 2
    //
    // Connect neighboring Surface Nets vertices.
    //
    // We build triangles into a u32 temporary index array.
    //
    // We don't upload this index buffer to Raylib because
    // Raylib's Mesh binding uses 16-bit indices.
    // ========================================================

    indices := make(
        [dynamic]u32,
    )
    defer delete(indices)


    // Rough reservation.
    reserve(
        &indices,
        len(vertices) * 6,
    )


    for z in 0..<cells {
        for y in 0..<cells {
            for x in 0..<cells {

                current := cell_vertices[
                    chunk_cell_index(
                        x,
                        y,
                        z,
                    )
                ]

                if current < 0 {
                    continue
                }


                // ------------------------------------------------
                // XY
                // ------------------------------------------------

                if x + 1 < cells &&
                   y + 1 < cells {

                    a := cell_vertices[
                        chunk_cell_index(
                            x + 1,
                            y,
                            z,
                        )
                    ]

                    b := cell_vertices[
                        chunk_cell_index(
                            x + 1,
                            y + 1,
                            z,
                        )
                    ]

                    c := cell_vertices[
                        chunk_cell_index(
                            x,
                            y + 1,
                            z,
                        )
                    ]

                    if a >= 0 &&
                       b >= 0 &&
                       c >= 0 {

                        append(
                            &indices,
                            u32(current),
                        )

                        append(
                            &indices,
                            u32(a),
                        )

                        append(
                            &indices,
                            u32(b),
                        )


                        append(
                            &indices,
                            u32(current),
                        )

                        append(
                            &indices,
                            u32(b),
                        )

                        append(
                            &indices,
                            u32(c),
                        )
                    }
                }


                // ------------------------------------------------
                // XZ
                // ------------------------------------------------

                if x + 1 < cells &&
                   z + 1 < cells {

                    a := cell_vertices[
                        chunk_cell_index(
                            x + 1,
                            y,
                            z,
                        )
                    ]

                    b := cell_vertices[
                        chunk_cell_index(
                            x + 1,
                            y,
                            z + 1,
                        )
                    ]

                    c := cell_vertices[
                        chunk_cell_index(
                            x,
                            y,
                            z + 1,
                        )
                    ]

                    if a >= 0 &&
                       b >= 0 &&
                       c >= 0 {

                        append(
                            &indices,
                            u32(current),
                        )

                        append(
                            &indices,
                            u32(a),
                        )

                        append(
                            &indices,
                            u32(b),
                        )


                        append(
                            &indices,
                            u32(current),
                        )

                        append(
                            &indices,
                            u32(b),
                        )

                        append(
                            &indices,
                            u32(c),
                        )
                    }
                }


                // ------------------------------------------------
                // YZ
                // ------------------------------------------------

                if y + 1 < cells &&
                   z + 1 < cells {

                    a := cell_vertices[
                        chunk_cell_index(
                            x,
                            y + 1,
                            z,
                        )
                    ]

                    b := cell_vertices[
                        chunk_cell_index(
                            x,
                            y + 1,
                            z + 1,
                        )
                    ]

                    c := cell_vertices[
                        chunk_cell_index(
                            x,
                            y,
                            z + 1,
                        )
                    ]

                    if a >= 0 &&
                       b >= 0 &&
                       c >= 0 {

                        append(
                            &indices,
                            u32(current),
                        )

                        append(
                            &indices,
                            u32(a),
                        )

                        append(
                            &indices,
                            u32(b),
                        )


                        append(
                            &indices,
                            u32(current),
                        )

                        append(
                            &indices,
                            u32(b),
                        )

                        append(
                            &indices,
                            u32(c),
                        )
                    }
                }
            }
        }
    }


    // --------------------------------------------------------
    // No triangles.
    // --------------------------------------------------------

    if len(indices) == 0 {
        return mesh
    }


    // ========================================================
    // Build a non-indexed mesh.
    //
    // Raylib's Mesh indices are 16-bit, so we simply expand
    // the indexed triangles into ordinary vertex arrays.
    //
    // This keeps this first implementation simple and avoids
    // the 65,535 vertex limitation of a u16 index buffer.
    // ========================================================

    final_vertex_count := len(indices)

    final_vertices := make(
        [dynamic]f32,
        final_vertex_count * 3,
    )
    defer delete(final_vertices)


    for index, vertex_index in indices {

        vertex := vertices[
            int(vertex_index)
        ]

        final_vertices[
            index * 3 + 0
        ] = vertex.x

        final_vertices[
            index * 3 + 1
        ] = vertex.y

        final_vertices[
            index * 3 + 2
        ] = vertex.z
    }


    // ========================================================
    // Normals.
    //
    // Because the mesh is non-indexed, every triangle has
    // its own three vertices.
    // ========================================================

    final_normals := make(
        [dynamic]f32,
        len(final_vertices),
    )
    defer delete(final_normals)


    triangle_count := final_vertex_count / 3


    for triangle := 0;
        triangle < triangle_count;
        triangle += 1 {

        vertex_a := triangle * 9
        vertex_b := vertex_a + 3
        vertex_c := vertex_a + 6


        a := [3]f32{
            final_vertices[vertex_a + 0],
            final_vertices[vertex_a + 1],
            final_vertices[vertex_a + 2],
        }

        b := [3]f32{
            final_vertices[vertex_b + 0],
            final_vertices[vertex_b + 1],
            final_vertices[vertex_b + 2],
        }

        c := [3]f32{
            final_vertices[vertex_c + 0],
            final_vertices[vertex_c + 1],
            final_vertices[vertex_c + 2],
        }


        ab := b - a
        ac := c - a

        normal := cross3(
            ab,
            ac,
        )

        normal = normalize3(
            normal,
        )


        final_normals[
            vertex_a + 0
        ] = normal.x

        final_normals[
            vertex_a + 1
        ] = normal.y

        final_normals[
            vertex_a + 2
        ] = normal.z


        final_normals[
            vertex_b + 0
        ] = normal.x

        final_normals[
            vertex_b + 1
        ] = normal.y

        final_normals[
            vertex_b + 2
        ] = normal.z


        final_normals[
            vertex_c + 0
        ] = normal.x

        final_normals[
            vertex_c + 1
        ] = normal.y

        final_normals[
            vertex_c + 2
        ] = normal.z
    }


    // ========================================================
    // Create Raylib Mesh.
    // ========================================================

    mesh.vertexCount = i32(final_vertex_count)

    mesh.triangleCount = i32(
        final_vertex_count / 3
    )


    vertex_byte_count :=
        len(final_vertices) *
        size_of(f32)


    // --------------------------------------------------------
    // Vertices
    // --------------------------------------------------------

    mesh.vertices = cast([^]f32)(
        rl.MemAlloc(
            u32(vertex_byte_count)
        )
    )


    for value, index in final_vertices {

        mesh.vertices[index] = value
    }


    // --------------------------------------------------------
    // Normals
    // --------------------------------------------------------

    mesh.normals = cast([^]f32)(
        rl.MemAlloc(
            u32(vertex_byte_count)
        )
    )


    for value, index in final_normals {

        mesh.normals[index] = value
    }


    // ========================================================
    // Upload to GPU.
    // ========================================================

    rl.UploadMesh(
        &mesh,
        false,
    )


    return mesh
}


// ============================================================
// Destroy a runtime chunk mesh.
//
// This DOES NOT destroy the Chunk.
//
// It only destroys the generated Raylib mesh.
// ============================================================

destroy_chunk_mesh :: proc( mesh: ^rl.Mesh, ) {

    rl.UnloadMesh(
        mesh^,
    )

    mesh^ = rl.Mesh{}
}


// ============================================================
// Read one density value from the chunk.
//
// The chunk is logically 3D, but the density array is flat.
// ============================================================

chunk_density :: proc( chunk: ^Chunk, x, y, z: int, ) -> f32 {

    index := chunk_index( x, y, z, )

    return f32(
        chunk.density[index]
    )
}


// ============================================================
// Convert 3D density coordinates to the flat array.
//
// X changes fastest:
//
// (0,0,0)
// (1,0,0)
// (2,0,0)
// ...
//
// Then Y.
//
// Then Z.
// ============================================================

chunk_index :: proc( x, y, z: int, ) -> int {

    return x + y * CHUNK_SIZE + z * CHUNK_SIZE * CHUNK_SIZE
}


// ============================================================
// Convert 3D cell coordinates to the Surface Nets
// cell_vertices array.
//
// A 64³ density grid contains 63³ cells.
// ============================================================

chunk_cell_index :: proc( x, y, z: int, ) -> int {

    cells := CHUNK_SIZE - 1

    return x + y * cells + z * cells * cells
}


// ============================================================
// Cross product.
// ============================================================

cross3 :: proc( a, b: [3]f32, ) -> [3]f32 {

    return {
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    }
}


// ============================================================
// Normalize a 3D vector.
// ============================================================

normalize3 :: proc( v: [3]f32, ) -> [3]f32 {

    length_squared := v.x * v.x + v.y * v.y + v.z * v.z


    if length_squared <= 0.000001 {
        return {0, 1, 0}
    }


    length := math.sqrt_f32(length_squared)

    return v / length
}
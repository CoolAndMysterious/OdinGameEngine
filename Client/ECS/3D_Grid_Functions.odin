package ECS

import "core:container/bit_array"
import "core:math"
import rl "vendor:raylib"


create_grid_3d :: proc(size: int) -> Grid_3D {
    grid := Grid_3D{
        size = size,
    }

    point_count := size * size * size

    resize(&grid.density, point_count)
    resize(&grid.material, point_count)

    // Everything initially becomes:
    //
    // density = 0
    // material = Air
    //
    // because Odin's resize allocation is zeroed.

    return grid
}

grid_index :: proc(size: int, x, y, z: int) -> int {
    return x + y*size + z*size*size
}

fill_test_cube :: proc(grid: ^Grid_3D) {
    size := grid.size

    for z in 0 ..< size {
        for y in 0 ..< size {
            for x in 0 ..< size {

                index := grid_index(size, x, y, z)

                if x >= 1 && x < size-1 &&
                   y >= 1 && y < size-1 &&
                   z >= 1 && z < size-1 {

                    grid.density[index] = 1.0
                    grid.material[index] = .Rock

                } else {

                    grid.density[index] = -1.0
                    grid.material[index] = .Air
                }
            }
        }
    }
}


generate_surface_nets :: proc(grid: ^Grid_3D) -> Surface_Nets_Mesh {
    mesh := Surface_Nets_Mesh{}

    size := grid.size

    if size < 2 {
        return mesh
    }

    cell_size := size - 1

    // --------------------------------------------------------
    // CELL -> SURFACE VERTEX
    // --------------------------------------------------------
    //
    // Every cell can have at most one Surface Nets vertex.
    //
    // -1 means this cell has no surface vertex.
    //

    cell_vertex := make([dynamic]i32)
    defer delete(cell_vertex)

    resize(
        &cell_vertex,
        cell_size * cell_size * cell_size,
    )

    for i in 0 ..< len(cell_vertex) {
        cell_vertex[i] = -1
    }


    // ========================================================
    // PASS 1
    // CREATE SURFACE NETS VERTICES
    // ========================================================

    for z in 0 ..< cell_size {
        for y in 0 ..< cell_size {
            for x in 0 ..< cell_size {

                values := [8]f32{
                    grid.density[grid_index(size, x,     y,     z)],
                    grid.density[grid_index(size, x + 1, y,     z)],
                    grid.density[grid_index(size, x,     y + 1, z)],
                    grid.density[grid_index(size, x + 1, y + 1, z)],

                    grid.density[grid_index(size, x,     y,     z + 1)],
                    grid.density[grid_index(size, x + 1, y,     z + 1)],
                    grid.density[grid_index(size, x,     y + 1, z + 1)],
                    grid.density[grid_index(size, x + 1, y + 1, z + 1)],
                }


                // ------------------------------------------------
                // DOES THIS CELL CONTAIN THE ISO-SURFACE?
                // ------------------------------------------------

                has_inside := false
                has_outside := false

                for value in values {
                    if value >= SURFACE_ISOVALUE {
                        has_inside = true
                    } else {
                        has_outside = true
                    }
                }

                if !has_inside || !has_outside {
                    continue
                }


                // ------------------------------------------------
                // CORNER POSITIONS
                // ------------------------------------------------

                positions := [8][3]f32{
                    {f32(x),     f32(y),     f32(z)},
                    {f32(x + 1), f32(y),     f32(z)},
                    {f32(x),     f32(y + 1), f32(z)},
                    {f32(x + 1), f32(y + 1), f32(z)},

                    {f32(x),     f32(y),     f32(z + 1)},
                    {f32(x + 1), f32(y),     f32(z + 1)},
                    {f32(x),     f32(y + 1), f32(z + 1)},
                    {f32(x + 1), f32(y + 1), f32(z + 1)},
                }


                // ------------------------------------------------
                // 12 CELL EDGES
                // ------------------------------------------------

                edges := [12][2]int{
                    {0, 1},
                    {1, 3},
                    {3, 2},
                    {2, 0},

                    {4, 5},
                    {5, 7},
                    {7, 6},
                    {6, 4},

                    {0, 4},
                    {1, 5},
                    {2, 6},
                    {3, 7},
                }


                average := [3]f32{}
                intersections := 0


                // ------------------------------------------------
                // FIND EDGE / ISO-SURFACE INTERSECTIONS
                // ------------------------------------------------

                for edge in edges {
                    a := edge[0]
                    b := edge[1]

                    va := values[a]
                    vb := values[b]

                    a_inside := va >= SURFACE_ISOVALUE
                    b_inside := vb >= SURFACE_ISOVALUE

                    if a_inside == b_inside {
                        continue
                    }

                    denominator := vb - va

                    t: f32 = 0.5

                    if math.abs(denominator) > 0.000001 {
                        t = (SURFACE_ISOVALUE - va) / denominator
                    }

                    pa := positions[a]
                    pb := positions[b]

                    point := [3]f32{
                        pa.x + (pb.x - pa.x) * t,
                        pa.y + (pb.y - pa.y) * t,
                        pa.z + (pb.z - pa.z) * t,
                    }

                    average += point
                    intersections += 1
                }


                if intersections == 0 {
                    continue
                }

                average /= f32(intersections)


                // ------------------------------------------------
                // STORE SURFACE VERTEX
                // ------------------------------------------------

                vertex_index := i32(len(mesh.vertices))

                append(&mesh.vertices, average)


                cell_index :=
                    x +
                    y*cell_size +
                    z*cell_size*cell_size

                cell_vertex[cell_index] = vertex_index
            }
        }
    }


    // ========================================================
    // PASS 2
    // GENERATE QUADS / TRIANGLES
    // ========================================================
    //
    // We process the three families of GRID EDGES:
    //
    // X edges
    // Y edges
    // Z edges
    //
    // Each surface-crossing grid edge is surrounded by
    // four neighboring cells.
    //
    // Their four Surface Nets vertices form one quad.
    //

    // --------------------------------------------------------
    // X-ALIGNED GRID EDGES
    // --------------------------------------------------------

    for z in 0 ..< size {
        for y in 0 ..< size {
            for x in 0 ..< size-1 {

                a := grid_index(size, x,     y, z)
                b := grid_index(size, x + 1, y, z)

                va := grid.density[a]
                vb := grid.density[b]

                if (va >= SURFACE_ISOVALUE) ==
                   (vb >= SURFACE_ISOVALUE) {
                    continue
                }

                // An X edge has four cells around it:
                //
                //       z
                //       ^
                //
                //   C2 ---- C3
                //    |      |
                //   C0 ---- C1
                //
                // where the cells differ in Y/Z.

                if y == 0 || z == 0 {
                    continue
                }

                c0 := cell_vertex[
                    (x) +
                    (y-1)*cell_size +
                    (z-1)*cell_size*cell_size
                ]

                c1 := cell_vertex[
                    (x) +
                    y*cell_size +
                    (z-1)*cell_size*cell_size
                ]

                c2 := cell_vertex[
                    (x) +
                    (y-1)*cell_size +
                    z*cell_size*cell_size
                ]

                c3 := cell_vertex[
                    (x) +
                    y*cell_size +
                    z*cell_size*cell_size
                ]

                if c0 < 0 || c1 < 0 || c2 < 0 || c3 < 0 {
                    continue
                }

                append(&mesh.indices,
                    u32(c0), u32(c2), u32(c3),
                    u32(c0), u32(c3), u32(c1),
                )
            }
        }
    }


    // --------------------------------------------------------
    // Y-ALIGNED GRID EDGES
    // --------------------------------------------------------

    for z in 0 ..< size {
        for y in 0 ..< size-1 {
            for x in 0 ..< size {

                a := grid_index(size, x,     y,     z)
                b := grid_index(size, x,     y + 1, z)

                va := grid.density[a]
                vb := grid.density[b]

                if (va >= SURFACE_ISOVALUE) ==
                   (vb >= SURFACE_ISOVALUE) {
                    continue
                }

                if x == 0 || z == 0 {
                    continue
                }

                c0 := cell_vertex[
                    (x-1) +
                    y*cell_size +
                    (z-1)*cell_size*cell_size
                ]

                c1 := cell_vertex[
                    x +
                    y*cell_size +
                    (z-1)*cell_size*cell_size
                ]

                c2 := cell_vertex[
                    (x-1) +
                    y*cell_size +
                    z*cell_size*cell_size
                ]

                c3 := cell_vertex[
                    x +
                    y*cell_size +
                    z*cell_size*cell_size
                ]

                if c0 < 0 || c1 < 0 || c2 < 0 || c3 < 0 {
                    continue
                }

                append(&mesh.indices,
                    u32(c0), u32(c1), u32(c3),
                    u32(c0), u32(c3), u32(c2),
                )
            }
        }
    }


    // --------------------------------------------------------
    // Z-ALIGNED GRID EDGES
    // --------------------------------------------------------

    for z in 0 ..< size-1 {
        for y in 0 ..< size {
            for x in 0 ..< size {

                a := grid_index(size, x, y,     z)
                b := grid_index(size, x, y, z + 1)

                va := grid.density[a]
                vb := grid.density[b]

                if (va >= SURFACE_ISOVALUE) ==
                   (vb >= SURFACE_ISOVALUE) {
                    continue
                }

                if x == 0 || y == 0 {
                    continue
                }

                c0 := cell_vertex[
                    (x-1) +
                    (y-1)*cell_size +
                    z*cell_size*cell_size
                ]

                c1 := cell_vertex[
                    x +
                    (y-1)*cell_size +
                    z*cell_size*cell_size
                ]

                c2 := cell_vertex[
                    (x-1) +
                    y*cell_size +
                    z*cell_size*cell_size
                ]

                c3 := cell_vertex[
                    x +
                    y*cell_size +
                    z*cell_size*cell_size
                ]

                if c0 < 0 || c1 < 0 || c2 < 0 || c3 < 0 {
                    continue
                }

                append(&mesh.indices,
                    u32(c0), u32(c2), u32(c3),
                    u32(c0), u32(c3), u32(c1),
                )
            }
        }
    }


    return mesh
}

surface_nets_to_raylib_mesh :: proc( source: ^Surface_Nets_Mesh, ) -> Raylib_Mesh {

    result := Raylib_Mesh{}

    vertex_count := len(source.vertices)
    index_count := len(source.indices)

    if vertex_count == 0 || index_count == 0 {
        return result
    }

    assert(
        vertex_count <= 65535,
        "Surface Nets mesh exceeds Raylib u16 index limit",
    )

    assert(
        index_count % 3 == 0,
        "Mesh index count must be divisible by 3",
    )


    // ========================================================
    // CPU VERTEX DATA
    // ========================================================

    result.vertices = make([]f32, vertex_count * 3)

    for i in 0 ..< vertex_count {
        result.vertices[i * 3 + 0] = source.vertices[i][0]
        result.vertices[i * 3 + 1] = source.vertices[i][1]
        result.vertices[i * 3 + 2] = source.vertices[i][2]
    }


    // ========================================================
    // CPU INDEX DATA
    // ========================================================

    result.indices = make([]u16, index_count)

    for i in 0 ..< index_count {

        index := source.indices[i]

        assert(
            index < u32(vertex_count),
            "Invalid Surface Nets index",
        )

        result.indices[i] = u16(index)
    }


    // ========================================================
    // CREATE RAYLIB MESH
    // ========================================================

    result.mesh.vertexCount = i32(vertex_count)
    result.mesh.triangleCount = i32(index_count / 3)

    result.mesh.vertices = raw_data(result.vertices)
    result.mesh.indices = raw_data(result.indices)


    return result
}

package ECS

import "core:container/bit_array"
import "core:math"
import rl "vendor:raylib"


Material :: enum u8 {
    Air,
    Dirt,
    Rock,
    Mud,
    Sand,
}

Grid_3D :: struct {
    size: int,

    // Authoritative simulation data.
    density: [dynamic]f32,
    material: [dynamic]Material,

    // Hierarchical activity maps.
    lod1: bit_array.Bit_Array,
    lod2: bit_array.Bit_Array,
    lod3: bit_array.Bit_Array,
}


SURFACE_ISOVALUE :: 0.0

Surface_Nets_Mesh :: struct {
    vertices: [dynamic][3]f32,
    indices:  [dynamic]u32,
}

Raylib_Mesh :: struct {
    mesh:    rl.Mesh,

    vertices: []f32,
    indices:  []u16,
}
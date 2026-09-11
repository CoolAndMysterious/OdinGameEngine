package ECS

WORLD_REGION_SIZE :: 8192
WORLD_GRID_MAX_DEPTH :: 20
WORLD_GRID_CHILD_COUNT :: 8
WORLD_GRID_MIN_RESOLUTION :: 0.01

World_Grid :: struct {
    origin: [3]int,
    tree: World_Grid_Tree,
}

World_Grid_Tree :: struct {
    root: World_Grid_Node,
}

World_Grid_Node :: struct {
    state: World_Grid_Node_State,
    value: World_Grid_Value,
    children: [dynamic]World_Grid_Node,
}

World_Grid_Node_State :: enum u8 {
    Uniform,
    Mixed,
    Leaf,
}

World_Grid_Value :: struct {
    density: f32,
    material: Material,
}


Material :: enum u8 {
    Air,
    Dirt,
    Rock,
    Mud,
    Sand,
}
package ECS

import "core:os"
import cbor "core:encoding/cbor"


SAVE_DIRECTORY :: "saves"
SAVE_FILE      :: "saves/grid_world.cbor"


// ============================================================
// SAVE WORLD
// ============================================================

save_grid_world :: proc(world: ^World_Grid) -> bool {

    // Make sure the saves directory exists.
    err := os.make_directory_all(SAVE_DIRECTORY)

    if err != nil {
        return false
    }


    // --------------------------------------------------------
    // Encode the entire World_Grid into CBOR.
    //
    // This saves:
    //
    //     world.chunks
    //     chunk coordinates
    //     chunk density
    //     chunk materials
    //     chunk active state
    // --------------------------------------------------------

    data, marshal_err := cbor.marshal_into_bytes(
        world^,
        cbor.ENCODE_SMALL,
    )

    if marshal_err != nil {
        return false
    }

    defer delete(data)


    // --------------------------------------------------------
    // Write the complete CBOR data to:
    //
    //     saves/world.cbor
    // --------------------------------------------------------

    write_err := os.write_entire_file_from_bytes(
        SAVE_FILE,
        data,
    )

    if write_err != nil {
        return false
    }

    return true
}


// ============================================================
// LOAD WORLD
// ============================================================

load_grid_world :: proc() -> (^World_Grid, bool) {

    // --------------------------------------------------------
    // Read the entire save file.
    // --------------------------------------------------------

    data, read_err := os.read_entire_file(
        SAVE_FILE,
        context.allocator,
    )

    if read_err != nil {
        return nil, false
    }

    defer delete(data)


    // --------------------------------------------------------
    // Create an empty World_Grid.
    //
    // CBOR will populate this structure.
    // --------------------------------------------------------

    world := new(World_Grid)


    // --------------------------------------------------------
    // Decode the complete World_Grid.
    // --------------------------------------------------------

    unmarshal_err := cbor.unmarshal_from_bytes(
        data,
        world,
    )

    if unmarshal_err != nil {
        free(world)
        return nil, false
    }


    return world, true
}
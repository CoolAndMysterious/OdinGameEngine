package main

import "core:fmt"
import "core:thread"
import net "Network"


main :: proc() {
    fmt.println("Hello, World!")
    //thread.create_and_start(net.network_update)
    net.network_update()
}
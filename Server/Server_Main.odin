package main

import "core:fmt"
import "vendor:ENet"


main :: proc() {
    fmt.println("Hello, World!")

    ENet.initialize()
    defer ENet.deinitialize()

    address := ENet.Address{
        host = ENet.HOST_ANY,
        port = 7777,
    }

    server := ENet.host_create(
        &address,
        32,
        1,
        0,
        0,
    )

    if server == nil {
        fmt.println("Failed to create server")
        return
    }

    defer ENet.host_destroy(server)

    fmt.println("Server running on port 7777")

    for {
        event: ENet.Event

        if ENet.host_service(server, &event, 1000) <= 0 {
            continue
        }

        switch event.type {
            case .NONE:
                fmt.println("Nande ???")
                continue

            case .CONNECT:
                fmt.println("Client connected!")

                message := "Hello from server!"

                packet := ENet.packet_create(
                raw_data(message),
                len(message),
                {.RELIABLE},
                )

                ENet.peer_send(event.peer, 0, packet)

            case .RECEIVE:
                message := string(event.packet.data[:event.packet.dataLength])

                fmt.println("Client says:", message)

                ENet.packet_destroy(event.packet)
                
            case .DISCONNECT:
                fmt.println("Client disconnected")
        }
    }
}
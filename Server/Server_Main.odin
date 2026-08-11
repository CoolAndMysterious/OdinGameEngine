package main

import "core:fmt"
import "vendor:ENet"
import net "Network"


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


    manager_address := ENet.Address{port = 9000,}

    //ENet.address_set_host(&address, "LOCALHOST")
    ENet.address_set_host_ip(&manager_address, "127.0.0.1")
    manager := ENet.host_connect(server, &manager_address, 1, 0, /* here goes the peer, channel i think. i might be wrong.*/)

    if manager == nil {
        fmt.println("Failed to connect")
        return
    }

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

                net.send_server_register(manager, 1)

            case .RECEIVE:
                message := string(event.packet.data[:event.packet.dataLength])

                fmt.println("Client says:", message)

                ENet.packet_destroy(event.packet)
                
            case .DISCONNECT:
                fmt.println("Client disconnected")
        }
    }
}
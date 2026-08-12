package Network

import "core:fmt"
import "vendor:ENet"

network_update :: proc(){
    
    ENet.initialize()
    defer ENet.deinitialize()

    address := ENet.Address{
        host = ENet.HOST_ANY,
        port = 7777,
    }

    server := ENet.host_create(&address, 32, 1, 0, 0,)

    if server == nil {
        fmt.println("Failed to create server")
        return
    }

    defer ENet.host_destroy(server)

    fmt.println("Server running on port 7777")

    event: ENet.Event
    for {
        if ENet.host_service(server, &event, 1000) <= 0 {
            continue
        }

        switch event.type {
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
                
            case .DISCONNECT:
                fmt.println("Client disconnected")

            case .NONE:
                continue
        }
    }
}
package main

import "core:fmt"

import ENet "vendor:ENet"
import net "Network"


main :: proc() {
	ENet.initialize()
    defer ENet.deinitialize()
    
    address := ENet.Address{
        host = ENet.HOST_ANY,
        port = 9000,
    }


    manager := ENet.host_create(&address, 32, 1, 0, 0,)
    if manager == nil {
        fmt.println("Failed to create Manager")
        return
    }
    defer ENet.host_destroy(manager)


    servers: [dynamic]^ENet.Peer


    event: ENet.Event
    for {
        if ENet.host_service(manager, &event, 1000) <= 0 {
            continue
        }

        switch event.type {
            case .NONE:
                continue
            case .CONNECT:
                fmt.println("Server connected!")
                append(&servers, event.peer)
                fmt.println("Server connected!")
                fmt.println("Total servers:", len(servers))

            case .RECEIVE:

                server_id, ok := net.receive_server_register(event.packet)
                ENet.packet_destroy(event.packet)
                if !ok{
                    continue
                }
                fmt.println("Server registered:", server_id)

            case .DISCONNECT:
                for peer, i in servers {
                    if peer == event.peer{
                        fmt.println("disconnecting server:", i)
                        unordered_remove(&servers, i)
                        fmt.println("disconnected",i)
			            break
                    }
                }
        }
    }
}
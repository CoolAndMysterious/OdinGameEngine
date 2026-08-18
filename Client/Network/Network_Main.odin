package Network

import "core:fmt"
import "vendor:ENet"

network_update :: proc() {

    // Initialzing the Enet.
    ENet.initialize()
    defer ENet.deinitialize()

    // Creating a Client Host.
    client := ENet.host_create(nil, 1, 1, 0, 0,)

    // Error checking for if client is not created properly or not found or some shee.
    if client == nil {
        fmt.println("Failed to create client")
        return
    }

    // Destroying Client Host Memory Upon Exit.
    defer ENet.host_destroy(client)

    /////////////////////////////////////////////////////

    // Settin up the Server Address that we want to connect to. BUTT only the port. we need to reference this struct variable forward.
    // to ENet.address_set_host_ip to set a ip ORRR ENet.address_set_host to set a host name instead of IP.
    address := ENet.Address{port = 7777,}

    //ENet.address_set_host(&address, "LOCALHOST")
    ENet.address_set_host_ip(&address, "127.0.0.1")


    // now we actually want to estabilish a connection. from Client. to The Serrverr. Let's GOOOO!!
    // basically we use the client. and the server ip. as you can see bellow. client, and server address and port reference.
    //channel count, data, and peerr Brrrrr.
    peer := ENet.host_connect(client, &address, 1, 0, /* here goes the peer, channel i think. i might be wrong.*/)

    if peer == nil {
        fmt.println("Failed to connect")
        return
    }

    fmt.println("Tryna Connecting...")

    
    event: ENet.Event
    for {
        if ENet.host_service(client, &event, 100) > 0 {

            switch event.type {

            case .CONNECT:
                fmt.println("Connected!")

            case .RECEIVE:
                fmt.println("Received packet!")

                packet := event.packet
                ENet.packet_destroy(event.packet)

            case .DISCONNECT:
                fmt.println("Disconnected")
                return

            case .NONE:
                //nothing happens.
            }
        }
    }
}
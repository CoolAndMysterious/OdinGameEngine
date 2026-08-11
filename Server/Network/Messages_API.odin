package Network

import ENet "vendor:ENet"


Message_Type :: enum u8 {
	Server_Register,
}



Server_Register_Message :: struct {
	type: Message_Type,
	id:   u64,
}


send_server_register :: proc(
	manager_peer: ^ENet.Peer,
	server_id: u64,
) {
	message := Server_Register_Message{
		type = .Server_Register,
		id   = server_id,
	}

	packet := ENet.packet_create(
		rawptr(&message),
		size_of(message),
		{.RELIABLE},
	)

	if packet == nil {
		return
	}

	ENet.peer_send(
		manager_peer,
		0,
		packet,
	)
}
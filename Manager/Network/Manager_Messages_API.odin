package Network

import "core:fmt"

import ENet "vendor:ENet"


Message_Type :: enum u8 {
	Server_Register,
}


Server_Register_Message :: struct {
	type: Message_Type,
	id:   u64,
}


receive_server_register :: proc(packet: ^ENet.Packet) -> (u64, bool) {

	if packet == nil {
		return 0, false
	}


	// Make sure this packet is large enough
	// to contain our message.
	if packet.dataLength < size_of(Server_Register_Message) {
		fmt.println("Invalid server register packet")
		return 0, false
	}


	// Interpret the packet data as our message.
	message := transmute(^Server_Register_Message)(
		packet.data
	)


	// Make sure this is actually a
	// Server_Register message.
	if message^.type != .Server_Register {
		fmt.println("Unknown message type")
		return 0, false
	}


	return message^.id, true
}
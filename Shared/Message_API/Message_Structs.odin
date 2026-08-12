package Message_API


Message :: struct {
	type: Message_Type,
	data: Message_Data,
}

Message_Data :: union {
	Server_Register,
	Client_Request,
	Server_Assignment,
}


Message_Type :: enum u8 {
	Server_Register,
	Client_Request,
	Server_Assignment,
}
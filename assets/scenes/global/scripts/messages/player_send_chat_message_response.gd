class_name PlayerSendChatMessageResponse extends Message


var display_name: String = "Guest"
var chat_text: String = "..."
var server_assigned_color: Color
var sender_id: int = 0


func _init(_display_name = "Guest", _chat_text = "...", _color = Color.WHITE, _sender_id = 0):
	display_name = _display_name
	chat_text = _chat_text
	server_assigned_color = _color
	sender_id = _sender_id
class_name PlayerSendChatMessageRequest extends Message


var display_name: String = "Guest"
var chat_text: String = "..."


func _init(_display_name = "Guest", _chat_text = "..."):
	display_name = _display_name
	chat_text = _chat_text

class_name PlayerConnectMessage extends Message


var display_name: String = "Guest"
var game_version = ProjectSettings.get_setting("application/config/version")

func _init(_display_name = "Guest"):
	display_name = _display_name

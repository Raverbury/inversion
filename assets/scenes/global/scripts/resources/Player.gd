class_name Player extends Object

var peer_id: int = 0
var is_ready: bool = false
var display_name: String = "Guest"
var player_game_data: PlayerGameData = null

func _init(pid = 0, _display_name = "Guest"):
	peer_id = pid
	display_name = _display_name
class_name Player extends RefCounted

var peer_id: int = 0
var is_ready: bool = false
var display_name: String = "Guest"
var player_game_data: PlayerGameData = null
var disconnected: bool = false

func _init(pid = 0, _display_name = "Guest"):
	peer_id = pid
	display_name = _display_name


func _to_string():
	return "Player %s (%d) %s" % [display_name, peer_id, player_game_data]

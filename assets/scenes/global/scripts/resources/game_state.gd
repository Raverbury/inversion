class_name GameState extends Object

var turn: int = 0
var player_move_order: Array = []
var turn_of_player: int = -1
var player_dict: Dictionary = {}

func _init(_pd = {}, spawn_pos = []):
	player_dict = _pd
	var i = 0
	for pid in player_dict:
		var player: Player = player_dict[pid]
		player.player_game_data.mapgrid_position = spawn_pos[i]
		i += 1


func advance_turn():
	for pid in player_dict:
		var player: Player = player_dict[pid]
		player.player_game_data.current_ap = player.player_game_data.max_ap
	turn += 1


func _to_string():
	return "Game on turn %s, currently pid %s's turn, %s" % [turn, turn_of_player, player_dict]

class_name GameState extends Object

var turn: int = -1
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
		player_move_order.append(pid)


func advance_turn():
	for pid in player_dict:
		var player: Player = player_dict[pid]
		player.player_game_data.current_ap = player.player_game_data.max_ap
	turn += 1
	turn_of_player = player_move_order[0]


func player_end_turn():
	var next_player = player_move_order.find(turn_of_player) + 1
	if next_player > len(player_move_order):
		turn_of_player = -1
		return true
	turn_of_player = player_move_order[next_player]
	return false


func _to_string():
	return "Game on turn %s, currently pid %s's turn, %s" % [turn, turn_of_player, player_dict]

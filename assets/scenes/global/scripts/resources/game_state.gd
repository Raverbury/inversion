class_name GameState extends Object

var turn: int = 0
var player_move_order: Array = []
var turn_of_player: int = -1
var player_dict: Dictionary = {}

enum RESULT {ON_GOING, WIN_LOSE, DRAW}

func _init(_pd = {}, spawn_pos = []):
	player_dict = _pd
	var i = 0
	for pid in player_dict:
		var player: Player = player_dict[pid]
		player.player_game_data.mapgrid_position = spawn_pos[i]
		i += 1
		player_move_order.append(pid)


func advance_turn():
	for pid in player_dict.keys():
		var player: Player = player_dict[pid]
		player.player_game_data.current_ap = player.player_game_data.max_ap
	turn += 1
	turn_of_player = player_move_order[0]


## Advances phase to the next player
## Gives phase to first player if current phase is of last player and advances turn count by 1
## Returns true if turn was advanced
func player_end_turn() -> bool:
	var next_player_id = __get_next_alive_player_id()
	turn_of_player = next_player_id
	if next_player_id == -1:
		advance_turn()
		return true
	return false


func __get_next_alive_player_id():
	var player_ids = player_dict.keys()
	var current_index = player_ids.find(turn_of_player)
	var next_index = current_index + 1
	while next_index < len(player_ids):
		var player: Player = player_dict[player_ids[next_index]]
		if player.player_game_data.current_hp > 0:
			return player.peer_id
		next_index += 1
	return -1


func get_alive_player_list():
	var result = []
	for pid in player_dict.keys():
		var player: Player = player_dict[pid]
		if player.player_game_data.current_hp > 0:
			result.append(player)
	return result


func _to_string():
	return "Game on turn %s, currently pid %s's turn, %s" % [turn, turn_of_player, player_dict]

class_name HealContext

var player_id: int = -1
var heal_amount: int
var game_state: GameState
var action_results: Array
var tile_map: GameTileMap

func _init(_player_id, _heal_amount, _game_state, _action_results, _tile_map):
	player_id = _player_id
	heal_amount = _heal_amount
	game_state = _game_state
	action_results = _action_results
	tile_map = _tile_map


func get_player() -> Player:
	return game_state.player_dict[player_id]
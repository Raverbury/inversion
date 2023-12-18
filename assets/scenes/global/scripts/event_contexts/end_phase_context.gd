class_name EndPhaseContext extends RefCounted

var player_id: int
var game_state: GameState
var action_results: Array
var tile_map: GameTileMap

func _init(_pid, _gs, _action_results, _tile_map):
	player_id = _pid
	game_state = _gs
	action_results = _action_results
	tile_map = _tile_map
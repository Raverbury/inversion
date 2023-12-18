class_name HealthChangeContext extends RefCounted

var player_id: int
var game_state: GameState
var action_results: Array
var tile_map: GameTileMap
var old_health: int
var new_health: int
var source_id: int

func _init(_pid, _src_id, _old_health, _new_health, _gs, _action_results, _tile_map):
	player_id = _pid
	source_id = _src_id
	old_health = _old_health
	new_health = _new_health
	game_state = _gs
	action_results = _action_results
	tile_map = _tile_map
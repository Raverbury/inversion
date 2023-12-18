class_name MoveContext extends RefCounted

var player_id: int
var move_steps: Array
var current_step: int
var game_state: GameState
var action_results: Array
var tile_map: GameTileMap

func _init(_pid, _move_steps, _gs, _action_results, _tile_map):
	player_id = _pid
	move_steps = _move_steps
	game_state = _gs
	current_step = -1
	action_results = _action_results
	tile_map = _tile_map


func advance_step():
	current_step += 1

class_name MoveContext

var player_id: int
var move_steps: Array
var current_step: int
var game_state: GameState
var action_results: Array

func _init(_pid, _move_steps, _gs, _action_results):
	player_id = _pid
	move_steps = _move_steps
	game_state = _gs
	current_step = -1
	action_results = _action_results


func advance_step():
	current_step += 1

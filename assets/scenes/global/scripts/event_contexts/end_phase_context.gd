class_name EndPhaseContext

var player_id: int
var game_state: GameState
var action_results: Array

func _init(_pid, _gs, _action_results):
	player_id = _pid
	game_state = _gs
	action_results = _action_results

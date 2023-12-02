class_name GameStartContext

var game_state: GameState
var action_results: Array

func _init(_gs, _action_results):
	game_state = _gs
	action_results = _action_results

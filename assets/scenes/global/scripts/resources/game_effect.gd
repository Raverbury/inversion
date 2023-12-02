class_name GameEffect

## 0 should be server aka for all players, >0 is normal player id, -1 is no one aka bug
var applier_id: int = -1
var target_id: int = -1
var is_activated: bool
var game_state: GameState
var effect_id: int = -1

func _init(_applier_id: int = -1, _target_id: int = -1, _game_state: GameState = null):
	applier_id = _applier_id
	target_id = _target_id
	game_state = _game_state


func activate(action_results: Array):
	if is_activated == true:
		return
	is_activated = true
	_abstract_on_activate(action_results)


func _abstract_on_activate(action_results: Array):
	push_error("Unimplemented abstract method")
	pass


func deactivate():
	if is_activated == false:
		return
	is_activated = false
	_abstract_on_deactivate()


func _abstract_on_deactivate():
	push_error("Unimplemented abstract method")
	pass


func expire(action_results):
	_abstract_on_expire(action_results)
	EventBus.effect_expired.emit(effect_id)
	pass


func _abstract_on_expire(action_results):
	push_error("Unimplemented abstract method")
	pass


func get_effect_description():
	push_error("Unimplemented abstract method")
	pass

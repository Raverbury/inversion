class_name GameEffect

## 0 should be server aka for all players, >0 is normal player id, -1 is no owner
var owner_id: int = -1
var is_activated: bool
var game_state: GameState

func _init(_owner_id: int):
	owner_id = _owner_id


func activate(_game_state: GameState):
	if is_activated == true:
		return
	game_state = _game_state
	is_activated = true
	_abstract_on_activate()


func _abstract_on_activate():
	pass


func deactivate():
	if is_activated == false:
		return
	is_activated = false
	_abstract_on_deactivate()


func _abstract_on_deactivate():
	pass
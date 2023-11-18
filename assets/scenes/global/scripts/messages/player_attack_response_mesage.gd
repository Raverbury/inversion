class_name PlayerAttackResponseMessage extends Message

var attacker_id: int
var target_mapgrid: Vector2i
var victims: Dictionary
var game_state: GameState
var result: GameState.RESULT
var victors: Array

func _init(_attacker_id = -1, _target_mapgrid = Vector2i.ZERO, _victims = {}, _game_state = null, _result = GameState.RESULT.ON_GOING, _victors = []):
	attacker_id = _attacker_id
	target_mapgrid = _target_mapgrid
	victims = _victims
	game_state = _game_state
	result = _result
	victors = _victors
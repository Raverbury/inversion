class_name PlayerMoveResponseMessage extends Message

var player_id: int
var move_steps: Array = []
var game_state: GameState

func _init(pid: int = -1, _move_steps: Array = [], _game_state: GameState = null):
	player_id = pid
	move_steps = _move_steps
	game_state = _game_state
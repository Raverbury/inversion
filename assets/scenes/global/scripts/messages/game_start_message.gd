class_name GameStartMessage extends Message

var game_state: GameState = null

func _init(_game_state = null):
	game_state = _game_state
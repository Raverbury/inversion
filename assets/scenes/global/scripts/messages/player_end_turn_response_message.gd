class_name PlayerEndTurnResponseMessage extends Message

var game_state: GameState

func _init(_game_state = null):
	game_state = _game_state
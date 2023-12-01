class_name GameConcludeResult extends ActionResult

var game_result: GameState.RESULT
var alive_list: Array

# to allow empty ctor
func set_stuff(_game_result, _alive_list):
	game_result = _game_result
	alive_list = _alive_list
	return self


# override
func show():
	EventBus.game_resolved.emit(game_result, alive_list[0].display_name)


func _to_string():
	return "<GameConcludeResult result: %s alive: %s>" % [game_result, alive_list]

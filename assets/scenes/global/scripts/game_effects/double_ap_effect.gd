class_name DoubleAPEffect extends GameEffect

## @override
func _abstract_on_activate(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DOUBLE AP APPLIED", Color.SKY_BLUE, false))
	__on_game_start(game_state)
	# EventBus.game_started.connect(__on_game_start)


## @override
func _abstract_on_deactivate():
	pass
	# EventBus.game_started.disconnect(__on_game_start)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DOUBLE AP EXPIRED", Color.DARK_GRAY, false))


func __on_game_start(_game_state: GameState):
	if target_id <= 0:
		return
	var player: Player = _game_state.player_dict[target_id]
	player.player_game_data.max_ap *= 2
	player.player_game_data.current_ap = player.player_game_data.max_ap


## @override
func get_effect_description():
	return "<Double AP> Double your maximum AP"


func get_effect_nameid() -> String:
	return "double_ap"


func get_max_instances_per_player() -> int:
	return 1
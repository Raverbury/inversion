class_name DoubleAPEffect extends GameEffect

## @override
func _abstract_on_activate():
	EventBus.game_started.connect(__on_game_start)


## @override
func _abstract_on_deactivate():
	EventBus.game_started.disconnect(__on_game_start)


## @override
func _abstract_on_expire():
	pass


func __on_game_start(_game_state: GameState):
	if target_id <= 0:
		return
	var player: Player = _game_state.player_dict[target_id]
	player.player_game_data.max_ap *= 2
	player.player_game_data.current_ap = player.player_game_data.max_ap


## @override
func get_effect_description():
	return "<Double AP> On game start, doubles your maximum AP"

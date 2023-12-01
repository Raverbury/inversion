class_name DoubleAPPerk extends GameEffect

## @override
func _abstract_on_activate():
	EventBus.game_started.connect(__on_game_start)


## @override
func _abstract_on_deactivate():
	EventBus.game_started.disconnect(__on_game_start)


func __on_game_start(_game_state: GameState):
	for player_id in _game_state.player_dict.keys():
		var player: Player = _game_state.player_dict[player_id]
		player.player_game_data.max_ap *= 2
		player.player_game_data.current_ap = player.player_game_data.max_ap


func _to_string():
	return "<Double AP: On game start, double your maximum AP>"

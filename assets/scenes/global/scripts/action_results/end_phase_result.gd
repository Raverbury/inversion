class_name EndPhaseResult extends ActionResult

var game_state: GameState

# to allow empty ctor
func set_stuff(_game_state: GameState):
	game_state = _game_state
	return self


# override in base
func show():
	EventBus.phase_display_finished.connect(__phase_display_finished_handler)
	EventBus.camera_force_panned.emit(Global.Util.global_coord_at(Vector2(
		game_state.player_dict[game_state.turn_of_player].player_game_data.mapgrid_position)), 1)
	EventBus.turn_displayed.emit(game_state.player_dict[game_state.turn_of_player].display_name,
		game_state.turn_of_player == Main.root_mp.get_unique_id(), game_state.turn)
	EventBus.turn_timer_refreshed.emit()


func __phase_display_finished_handler():
	EventBus.phase_display_finished.disconnect(__phase_display_finished_handler)
	finished.emit()


func _to_string():
	return "<EndPhaseResult>"

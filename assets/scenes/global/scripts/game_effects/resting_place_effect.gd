class_name RestingPlaceEffect extends GameEffect

const HEAL_AMOUNT = 3

## @override
func _abstract_on_activate(_action_results: Array):
# func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "RESTING PLACE APPLIED", Color.FOREST_GREEN, false))
	EventBus.phase_end_declared.connect(__on_phase_end)


## @override
func _abstract_on_deactivate():
	EventBus.phase_end_declared.disconnect(__on_phase_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "RESTING PLACE EXPIRED", Color.DARK_GRAY, false))
	pass


func __on_phase_end(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	if end_phase_context.player_id != target_id:
		return
	var tmp_heal_context = HealContext.new(target_id, HEAL_AMOUNT, end_phase_context.game_state, end_phase_context.action_results, end_phase_context.tile_map)
	var tile_name: String = end_phase_context.tile_map.get_data_at(end_phase_context.game_state.player_dict[target_id].player_game_data.mapgrid_position, "name", "")
	if not "house" in tile_name.to_lower():
		return
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "RESTING", Color.FOREST_GREEN, false))
	EventBus.player_healed.emit(tmp_heal_context)


## @override
func get_effect_description():
	return "<Resting Place> Recover %d health at the end of your phase when in a house" % [HEAL_AMOUNT]


func get_effect_nameid() -> String:
	return "resting_place"


func get_max_instances_per_player() -> int:
	return 1
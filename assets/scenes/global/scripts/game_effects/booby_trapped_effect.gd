class_name BoobyTrappedEffect extends GameEffect

const HEALTH_LOSS = 5

## @override
func _abstract_on_activate(_action_results: Array):
# func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BOOBY TRAPPED APPLIED", Color.PURPLE, false))
	EventBus.tile_entered.connect(__on_tile_enter)


## @override
func _abstract_on_deactivate():
	EventBus.tile_entered.disconnect(__on_tile_enter)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BOOBY TRAPPED EXPIRED", Color.LIGHT_SEA_GREEN, false))
	pass


func __on_tile_enter(move_context: MoveContext):
	if target_id <= 0:
		return
	if move_context.player_id != target_id:
		return
	var tile_name: String = move_context.tile_map.get_data_at(move_context.game_state.player_dict[target_id].player_game_data.mapgrid_position, "name", "")
	if not "house" in tile_name.to_lower():
		return
	var fake_attack_context = AttackContext.new(0, Vector2i.ZERO, move_context.game_state, [], target_id, move_context.action_results, move_context.tile_map)
	fake_attack_context.health_to_lose = HEALTH_LOSS
	move_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BOOBY TRAPPED ACTIVATED", Color.PURPLE, false))
	EventBus.player_lost_health.emit(fake_attack_context)


## @override
func get_effect_description():
	return "<Booby Trapped> Lose %d health when entering a house" % [HEALTH_LOSS]


func get_effect_nameid() -> String:
	return "booby_trapped"


func get_max_instances_per_player() -> int:
	return 1
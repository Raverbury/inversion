class_name RegenerationEffect extends GameEffect

var turn_ticked = 0
const HEAL_DURATION = 3
const HEAL_AMOUNT = 2

## @override
func _abstract_on_activate(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "REGENERATION APPLIED", Color.PINK, false))
	EventBus.phase_end_declared.connect(__on_phase_end)


## @override
func _abstract_on_deactivate():
	EventBus.phase_end_declared.disconnect(__on_phase_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "REGENERATION EXPIRED", Color.DARK_GRAY, false))
	pass


func __on_phase_end(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	if end_phase_context.player_id != target_id:
		return
	var tmp_heal_context = HealContext.new(target_id, HEAL_AMOUNT, end_phase_context.game_state, end_phase_context.action_results, end_phase_context.tile_map)
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "REGENERATION ACTIVATED", Color.PINK, false))
	EventBus.player_healed.emit(tmp_heal_context)
	turn_ticked += 1
	if turn_ticked >= HEAL_DURATION:
		expire(end_phase_context.action_results)


## @override
func get_effect_description():
	return "<Regeneration> Recover %d health at the end of your phase for %d turn(s) (%s turn(s) left)" % [HEAL_AMOUNT, HEAL_DURATION, HEAL_DURATION - turn_ticked]


func get_effect_nameid() -> String:
	return "regeneration"


func get_max_instances_per_player() -> int:
	return 1
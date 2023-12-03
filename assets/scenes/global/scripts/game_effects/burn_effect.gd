class_name BurnEffect extends GameEffect

var turn_ticked = 0
const BURN_DURATION = 3
const BURN_DAMAGE = 2

## @override
func _abstract_on_activate(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BURNED", Color.ORANGE, false))
	EventBus.phase_end_declared.connect(__on_phase_end)


## @override
func _abstract_on_deactivate():
	EventBus.phase_end_declared.disconnect(__on_phase_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BURN EXPIRED", Color.LIGHT_SEA_GREEN, false))


func __on_phase_end(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	if end_phase_context.player_id != target_id:
		return
	var tmp_attack_context = AttackContext.new(applier_id, Vector2i.ZERO, end_phase_context.game_state,
		[], target_id, end_phase_context.action_results, end_phase_context.tile_map)
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BURNING", Color.ORANGE, false))
	tmp_attack_context.health_to_lose = BURN_DAMAGE
	EventBus.player_lost_health.emit(tmp_attack_context)
	turn_ticked += 1
	if turn_ticked >= BURN_DURATION:
		expire(end_phase_context.action_results)


## @override
func get_effect_description():
	return "<Burn> Lose %d health at the end of your phase for %d turn(s) (%d turn(s) left)" % [BURN_DAMAGE, BURN_DURATION, BURN_DURATION - turn_ticked]


func get_effect_nameid() -> String:
	return "burn"


func get_max_instances_per_player() -> int:
	return 1
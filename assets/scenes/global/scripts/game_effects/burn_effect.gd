class_name BurnEffect extends GameEffect

var turn_ticked = 0
const BURN_DURATION = 3
const BURN_DAMAGE = 2

## @override
func _abstract_on_activate(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BURNED", Color.ORANGE, false))
	EventBus.phase_ended.connect(__on_phase_end)


## @override
func _abstract_on_deactivate():
	EventBus.phase_ended.disconnect(__on_phase_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BURN EXPIRED", Color.ORANGE, false))


func __on_phase_end(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	var tmp_attack_context = AttackContext.new(applier_id, Vector2i.ZERO, end_phase_context.game_state,
		[], target_id, end_phase_context.action_results)
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BURN ACTIVATED", Color.RED, false))
	tmp_attack_context.health_to_lose = BURN_DAMAGE
	EventBus.player_lost_health.emit(tmp_attack_context)
	turn_ticked += 1
	if turn_ticked >= BURN_DURATION:
		expire(end_phase_context.action_results)


## @override
func get_effect_description():
	return "<Burn> Lose %d health at the end of your phase for %d turn(s)" % [BURN_DAMAGE, BURN_DURATION]

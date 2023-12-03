class_name IncendiaryRoundEffect extends GameEffect

const BURN_CHANCE = 15.0

## @override
func _abstract_on_activate(_action_results: Array):
# func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "INCENDIARY ROUND APPLIED", Color.ORANGE, false))
	EventBus.attack_individual_hit.connect(__on_attack_individual_hit)


## @override
func _abstract_on_deactivate():
	EventBus.attack_individual_hit.disconnect(__on_attack_individual_hit)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "INCENDIARY ROUND EXPIRED", Color.DARK_GRAY, false))
	pass


func __on_attack_individual_hit(attack_context: AttackContext):
	if target_id <= 0:
		return
	if attack_context.attacker_id != target_id:
		return
	var success = Global.Util.roll_float_on_scale_100(BURN_CHANCE)
	if success == false:
		return
	attack_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "INCENDIARY ROUND", Color.ORANGE, false))
	EventBus.effect_applied_to_player.emit(target_id, attack_context.current_target_id, BurnEffect, attack_context.action_results)


## @override
func get_effect_description():
	return "<Incendiary Round> Have a %.2f%% chance to apply BURN to your target when your attack hits" % [BURN_CHANCE]


func get_effect_nameid() -> String:
	return "incendiary_round"


func get_max_instances_per_player() -> int:
	return 1
class_name PerseveranceEffect extends GameEffect

const HEALTH_GAIN = 2.0
const ACTIVATION_INTERVAL = 2
var attack_counter: int = 0

## @override
func get_effect_description():
	return "<Perseverance> Recover %d health after being hit by %d attack(s) (%d attack(s) left)" % [
		HEALTH_GAIN, ACTIVATION_INTERVAL + 1, ACTIVATION_INTERVAL + 1 - attack_counter]


func get_effect_nameid() -> String:
	return "perseverance"


func get_max_instances_per_player() -> int:
	return 1


## @override
func _abstract_on_activate(_action_results: Array):
# func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "PERSEVERANCE APPLIED", Color.STEEL_BLUE, false))
	EventBus.attack_individual_hit_after_damage.connect(__on_attack_individual_hit_after_damage)


## @override
func _abstract_on_deactivate():
	EventBus.attack_individual_hit_after_damage.disconnect(__on_attack_individual_hit_after_damage)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "PERSEVERANCE EXPIRED", Color.DARK_GRAY, false))


func __on_attack_individual_hit_after_damage(attack_context: AttackContext):
	if target_id <= 0:
		return
	if attack_context.current_target_id != target_id:
		return
	attack_counter += 1
	if attack_counter > ACTIVATION_INTERVAL:
		attack_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "PERSEVERANCE ACTIVATED", Color.STEEL_BLUE, false))
		var fake_heal_context = HealContext.new(attack_context.current_target_id, HEALTH_GAIN, attack_context.game_state,
			attack_context.action_results, attack_context.tile_map)
		EventBus.player_healed.emit(fake_heal_context)
		attack_counter = 0

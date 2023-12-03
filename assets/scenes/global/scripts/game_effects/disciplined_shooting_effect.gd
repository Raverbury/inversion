class_name DisciplinedShootingEffect extends GameEffect

const BONUS_ACCURACY = 10.0
const ACTIVATION_INTERVAL = 2
var attack_counter: int = 0

## @override
func get_effect_description():
	return "<Disciplined Shooting> Gain %d accuracy for your next attack after %d attack(s) (%d attack(s) left)" % [
		BONUS_ACCURACY, ACTIVATION_INTERVAL, ACTIVATION_INTERVAL - attack_counter]


func get_effect_nameid() -> String:
	return "disciplined_shooting"


func get_max_instances_per_player() -> int:
	return 1


## @override
func _abstract_on_activate(_action_results: Array):
# func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DICIPLINED SHOOTING APPLIED", Color.TEAL, false))
	EventBus.attack_concluded.connect(__on_attack_conclude)


## @override
func _abstract_on_deactivate():
	EventBus.attack_concluded.disconnect(__on_attack_conclude)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DISCIPLINED SHOOTING EXPIRED", Color.DARK_GRAY, false))
	if ACTIVATION_INTERVAL == attack_counter:
		return
	game_state.player_dict[target_id].player_game_data.accuracy -= BONUS_ACCURACY
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DISCIPLINED SHOOTING'S EFFECT REMOVED", Color.TEAL, false))


func __on_attack_conclude(attack_context: AttackContext):
	if target_id <= 0:
		return
	if attack_context.attacker_id != target_id:
		return
	attack_counter += 1
	if ACTIVATION_INTERVAL == attack_counter:
		game_state.player_dict[target_id].player_game_data.accuracy += BONUS_ACCURACY
		attack_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DISCIPLINED SHOOTING", Color.TEAL, false))
	elif attack_counter > ACTIVATION_INTERVAL:
		game_state.player_dict[target_id].player_game_data.accuracy -= BONUS_ACCURACY
		attack_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "DISCIPLINED SHOOTING'S EFFECT REMOVED", Color.TEAL, false))
		attack_counter = 0

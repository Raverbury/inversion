class_name StabilizedAimEffect extends GameEffect

const BONUS_ACCURACY = 30.0
var has_attacked_this_turn: bool = false

## @override
func get_effect_description():
	return "<Stabilized Aim> Gain %d accuracy for your first attack each turn (%s)" % [BONUS_ACCURACY, "spent" if has_attacked_this_turn else "in-stock"]


func get_effect_nameid() -> String:
	return "stabilized_aim"


func get_max_instances_per_player() -> int:
	return 1


## @override
# func _abstract_on_activate(_action_results: Array):
func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "STABILIZED AIM APPLIED", Color.TEAL, false))
	EventBus.attack_concluded.connect(__on_attack_conclude)
	EventBus.phase_end_declared.connect(__on_phase_end_declare)
	if has_attacked_this_turn == true:
		return
	game_state.player_dict[target_id].player_game_data.accuracy += BONUS_ACCURACY
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "ACC UP", Color.TEAL, false))


## @override
func _abstract_on_deactivate():
	EventBus.attack_concluded.disconnect(__on_attack_conclude)
	EventBus.phase_end_declared.disconnect(__on_phase_end_declare)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "STABILIZED AIM EXPIRED", Color.DARK_GRAY, false))
	if has_attacked_this_turn == true:
		return
	game_state.player_dict[target_id].player_game_data.accuracy -= BONUS_ACCURACY
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "ACC DOWN", Color.TEAL, false))


func __on_attack_conclude(attack_context: AttackContext):
	if target_id <= 0:
		return
	if attack_context.attacker_id != target_id:
		return
	if has_attacked_this_turn == true:
		return
	game_state.player_dict[target_id].player_game_data.accuracy -= BONUS_ACCURACY
	attack_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "ACC DOWN", Color.TEAL, false))
	has_attacked_this_turn = true


func __on_phase_end_declare(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	if end_phase_context.player_id != target_id:
		return
	if has_attacked_this_turn == false:
		return
	game_state.player_dict[target_id].player_game_data.accuracy += BONUS_ACCURACY
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "ACC UP", Color.TEAL, false))
	has_attacked_this_turn = false

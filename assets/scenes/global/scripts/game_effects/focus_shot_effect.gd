class_name FocusShotEffect extends GameEffect

var stack_counter: int = 0
var attack_declared_last_turn: bool = false
const MAX_STACK: int = 2
const ATTACK_POWER_INCREASE: int = 1
var original_attack_power: int

## @override
func _abstract_on_activate(_action_results: Array):
	# _action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "FOCUS SHOT APPLIED", Color.MEDIUM_VIOLET_RED, false))
	var target_player: Player = game_state.player_dict[target_id]
	original_attack_power = target_player.player_game_data.attack_power
	EventBus.attack_concluded.connect(__on_attack_conclude)
	EventBus.phase_end_declared.connect(__on_phase_end)


## @override
func _abstract_on_deactivate():
	EventBus.attack_concluded.disconnect(__on_attack_conclude)
	EventBus.phase_end_declared.disconnect(__on_phase_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "FOCUS SHOT EXPIRED", Color.DARK_GRAY, false))
	pass


func __on_attack_conclude(attack_context: AttackContext):
	if attack_context.attacker_id != target_id:
		return
	if stack_counter > 0:
		var target_player: Player = game_state.player_dict[target_id]
		target_player.player_game_data.attack_power = original_attack_power
		attack_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "FOCUS SHOT'S EFFECT REMOVED", Color.DARK_GRAY, false))
	stack_counter = 0
	attack_declared_last_turn = true


func __on_phase_end(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	if end_phase_context.player_id != target_id:
		return
	if attack_declared_last_turn == true:
		attack_declared_last_turn = false
		return
	attack_declared_last_turn = false
	if stack_counter >= MAX_STACK:
		return
	var target_player: Player = game_state.player_dict[target_id]
	target_player.player_game_data.attack_power += ATTACK_POWER_INCREASE
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "FOCUS SHOT", Color.MEDIUM_VIOLET_RED, false))
	stack_counter += 1


## @override
func get_effect_description():
	return "<Focus Shot> Increase attack power by %s when not attacking for 1 turn, max %s stack(s); reset upon attacking (current stack(s): %s)" % \
		[ATTACK_POWER_INCREASE, MAX_STACK, stack_counter]


func get_effect_nameid() -> String:
	return "focus_shot"


func get_max_instances_per_player() -> int:
	return 1
class_name HappyCamperEffect extends GameEffect

var stack_counter: int = 0
var move_declared_last_turn: bool = false
const MAX_STACK: int = 2
const ATTACK_RANGE_INCREASE: int = 1
const HIT_RATE_MODIFIER: float = 1.0
const ACCURACY_INCREASE: int = 5
var original_ranged_acc_modifier
var original_acc

## @override
func _abstract_on_activate(_action_results: Array):
	# _action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "HAPPY CAMPER APPLIED", Color.MEDIUM_VIOLET_RED, false))
	var target_player: Player = game_state.player_dict[target_id]
	original_ranged_acc_modifier = target_player.player_game_data.ranged_accuracy_modifier
	original_acc = target_player.player_game_data.accuracy
	EventBus.movement_concluded.connect(__on_movement_declare)
	EventBus.phase_end_declared.connect(__on_phase_end)


## @override
func _abstract_on_deactivate():
	EventBus.movement_concluded.disconnect(__on_movement_declare)
	EventBus.phase_end_declared.disconnect(__on_phase_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "HAPPY CAMPER EXPIRED", Color.DARK_GRAY, false))
	pass


func __on_movement_declare(move_context: MoveContext):
	if move_context.player_id != target_id:
		return
	if stack_counter > 0:
		var target_player: Player = game_state.player_dict[target_id]
		target_player.player_game_data.ranged_accuracy_modifier = original_ranged_acc_modifier
		target_player.player_game_data.accuracy = original_acc
		target_player.player_game_data.attack_range = len(original_ranged_acc_modifier) - 1
		move_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "HAPPY CAMPER'S EFFECT REMOVED", Color.DARK_GRAY, false))
	stack_counter = 0
	move_declared_last_turn = true


func __on_phase_end(end_phase_context: EndPhaseContext):
	if target_id <= 0:
		return
	if end_phase_context.player_id != target_id:
		return
	if move_declared_last_turn == true:
		move_declared_last_turn = false
		return
	move_declared_last_turn = false
	if stack_counter >= MAX_STACK:
		return
	var target_player: Player = game_state.player_dict[target_id]
	var tmp_ram = target_player.player_game_data.ranged_accuracy_modifier.duplicate()
	tmp_ram.append(HIT_RATE_MODIFIER)
	target_player.player_game_data.ranged_accuracy_modifier = tmp_ram
	target_player.player_game_data.accuracy += ACCURACY_INCREASE
	target_player.player_game_data.attack_range = len(target_player.player_game_data.ranged_accuracy_modifier) - 1
	end_phase_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "HAPPY CAMPER", Color.MEDIUM_VIOLET_RED, false))
	stack_counter += 1


## @override
func get_effect_description():
	return "<Happy Camper> Increase attack range by %s (%.1f hit rate modifier) and accuracy by %s after not moving for 1 turn, max %s stack(s); reset upon moving (current stack(s): %d)" % \
		[ATTACK_RANGE_INCREASE, HIT_RATE_MODIFIER, ACCURACY_INCREASE, MAX_STACK, stack_counter]


func get_effect_nameid() -> String:
	return "happy_camper"


func get_max_instances_per_player() -> int:
	return 1

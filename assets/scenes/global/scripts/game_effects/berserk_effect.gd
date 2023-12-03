class_name BerserkEffect extends GameEffect

const PERCENT_HEALTH_LOSS_THRESHOLD = 40.0
const BONUS_MAX_AP = 2
var is_in_effect: bool = false

## @override
func get_effect_description():
	return "<Berserk> Gain %d max AP(s) while missing %.1f%% or more health (%s)" % [
		BONUS_MAX_AP, PERCENT_HEALTH_LOSS_THRESHOLD, "in-effect" if is_in_effect else "inactive"]


func get_effect_nameid() -> String:
	return "berserk"


func get_max_instances_per_player() -> int:
	return 1


## @override
# func _abstract_on_activate(_action_results: Array):
func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BERSERK APPLIED", Color.STEEL_BLUE, false))
	EventBus.player_health_changed.connect(__on_player_health_change)
	var player: Player = game_state.player_dict[target_id]
	var percent_health_missing = (float(player.player_game_data.max_hp) - float(player.player_game_data.current_hp)) / float(float(player.player_game_data.max_hp)) * 100.0
	if percent_health_missing >= PERCENT_HEALTH_LOSS_THRESHOLD:
		player.player_game_data.max_ap += BONUS_MAX_AP
		action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BERSERK", Color.STEEL_BLUE, false))
		is_in_effect = true


## @override
func _abstract_on_deactivate():
	EventBus.player_health_changed.disconnect(__on_player_health_change)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BERSERK EXPIRED", Color.DARK_GRAY, false))


func __on_player_health_change(health_change_context: HealthChangeContext):
	if target_id <= 0:
		return
	if health_change_context.player_id != target_id:
		return
	var player: Player = health_change_context.game_state.player_dict[target_id]
	var percent_health_missing = (float(player.player_game_data.max_hp) - float(health_change_context.new_health)) / float(float(player.player_game_data.max_hp)) * 100.0
	if is_in_effect == true:
		if percent_health_missing < PERCENT_HEALTH_LOSS_THRESHOLD:
			player.player_game_data.max_ap -= BONUS_MAX_AP
			health_change_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BERSERK'S EFFECT REMOVED", Color.DARK_GRAY, false))
			is_in_effect = false
	else:
		if percent_health_missing >= PERCENT_HEALTH_LOSS_THRESHOLD:
			player.player_game_data.max_ap += BONUS_MAX_AP
			health_change_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "BERSERK", Color.STEEL_BLUE, false))
			is_in_effect = true

class_name NomadEffect extends GameEffect

var proc_counter = 0
const AP_RESTORE: int = 1
const MAX_ACTIVATIONS: int = 3
var last_tile_names = {}

## @override
func _abstract_on_activate(_action_results: Array):
# func _abstract_on_activate(action_results: Array):
	# action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "NOMAD APPLIED", Color.TURQUOISE, false))
	EventBus.tile_left.connect(__on_tile_leave)
	EventBus.tile_entered.connect(__on_tile_enter)
	EventBus.turn_ended.connect(__on_turn_end)


## @override
func _abstract_on_deactivate():
	EventBus.tile_left.disconnect(__on_tile_leave)
	EventBus.tile_entered.disconnect(__on_tile_enter)
	EventBus.turn_ended.disconnect(__on_turn_end)


## @override
func _abstract_on_expire(action_results: Array):
	action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "NOMAD EXPIRED", Color.DARK_GRAY, false))
	pass


func __on_tile_leave(move_context: MoveContext):
	if target_id <= 0:
		return
	if move_context.player_id != target_id:
		return
	last_tile_names[move_context.tile_map.get_data_at(move_context.game_state.player_dict[target_id].player_game_data.mapgrid_position, "name", "")] = 1


func __on_tile_enter(move_context: MoveContext):
	if target_id <= 0:
		return
	if move_context.player_id != target_id:
		return
	if proc_counter >= MAX_ACTIVATIONS:
		return
	var current_tile_name = move_context.tile_map.get_data_at(move_context.game_state.player_dict[target_id].player_game_data.mapgrid_position, "name", "")
	if last_tile_names.has(current_tile_name):
		return
	move_context.game_state.player_dict[target_id].player_game_data.current_ap += AP_RESTORE
	move_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "NOMAD", Color.TURQUOISE, false))
	# move_context.action_results.append(PopupFeedbackResult.new().set_stuff(target_id, "+%dAP" % AP_RESTORE, Color.TURQUOISE, false))
	proc_counter += 1


func __on_turn_end():
	proc_counter = 0
	last_tile_names.clear()


## @override
func get_effect_description():
	return "<Nomad> Restore %d AP(s) when you enter a new type of tile this turn, max %d time(s) per turn (%d time(s) left)" % [
		AP_RESTORE, MAX_ACTIVATIONS, MAX_ACTIVATIONS - proc_counter]


func get_effect_nameid() -> String:
	return "nomad"


func get_max_instances_per_player() -> int:
	return 1
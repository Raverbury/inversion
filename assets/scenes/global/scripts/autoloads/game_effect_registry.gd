extends Node

var effect_dict: Dictionary = {}
## Nested dictionary to provide effect indexing on player id
var effect_by_player_dict: Dictionary = {}
## Nested dictionary to keep track of instances of effect per player
var effect_counts_by_player_dict: Dictionary = {}

var internal_counter = 0

func _ready():
	EventBus.effect_expired.connect(remove_effect_by_id)


## Clears all effects and deactivate them
func clear():
	internal_counter = 0
	for eid in effect_dict.keys():
		var effect: GameEffect = effect_dict[eid]
		effect.deactivate()
	effect_dict.clear()
	effect_by_player_dict.clear()
	effect_counts_by_player_dict.clear()


func __get_next_availble_id():
	internal_counter += 1
	return internal_counter


## Adds an effect globally (aka with applier id = 0)
func add_effect_globally(pid_list: Array, effect: GameEffect, action_results: Array):
	for pid in pid_list:
		add_effect_to_player(0, pid, effect, action_results)


func __reach_max_instances(target_id: int, effect_nameid: String, max_instances: int) -> bool:
	if max_instances <= 0:
		return true
	return __get_effect_instances(target_id, effect_nameid) >= max_instances


func __get_effect_instances(target_id: int, effect_nameid: String):
	if not effect_counts_by_player_dict.has(target_id):
		effect_counts_by_player_dict[target_id] = {}
	if not effect_counts_by_player_dict[target_id].has(effect_nameid):
		effect_counts_by_player_dict[target_id][effect_nameid] = 0
	return effect_counts_by_player_dict[target_id][effect_nameid]


func __add_effect_instances(target_id: int, effect_nameid: String, instances: int):
	if not effect_counts_by_player_dict.has(target_id):
		effect_counts_by_player_dict[target_id] = {}
	if not effect_counts_by_player_dict[target_id].has(effect_nameid):
		effect_counts_by_player_dict[target_id][effect_nameid] = 0
	effect_counts_by_player_dict[target_id][effect_nameid] += instances


func __remove_effect_instances(target_id: int, effect_nameid: String, instances: int):
	if not effect_counts_by_player_dict.has(target_id):
		return
	if not effect_counts_by_player_dict[target_id].has(effect_nameid):
		return
	effect_counts_by_player_dict[target_id][effect_nameid] -= instances


## Adds an effect to a player
func add_effect_to_player(applier_id: int, target_id: int, effect: GameEffect, action_results: Array):
	var effect_id = __get_next_availble_id()
	if effect_dict.has(effect_id):
		push_error("Duplicate effect id")
		return
	var effect_nameid = effect.get_effect_nameid()
	var max_instances = effect.get_max_instances_per_player()
	if __reach_max_instances(target_id, effect_nameid, max_instances):
		print("Effect reaches max number of instances allowed, aborting, %s on %s: %s/%s" % [
			effect_nameid, target_id, __get_effect_instances(target_id, effect_nameid), max_instances])
		return
	effect.effect_id = effect_id
	effect.applier_id = applier_id
	effect.target_id = target_id
	effect.activate(action_results)
	effect_dict[effect_id] = effect
	if effect_by_player_dict.has(target_id):
		effect_by_player_dict[target_id][effect_id] = effect
	else:
		effect_by_player_dict[target_id] = {effect_id: effect}
	__add_effect_instances(target_id, effect_nameid, 1)
	EventBus.effect_applied_to_player_success.emit(applier_id, target_id, effect, action_results)


## Removes an effect by its id
func remove_effect_by_id(effect_id: int):
	if not effect_dict.has(effect_id):
		push_warning("Effect ID %s does not exist in registry" % effect_id)
		return
	var target_effect: GameEffect = effect_dict[effect_id]
	var effect_nameid = target_effect.get_effect_nameid()
	var target_id = target_effect.target_id
	effect_dict.erase(effect_id)
	effect_by_player_dict[target_effect.target_id].erase(effect_id)
	target_effect.deactivate()
	__remove_effect_instances(target_id, effect_nameid, 1)


## Removes all effects from a player
func remove_all_effects_from_player(player_id: int):
	if not effect_by_player_dict.has(player_id):
		push_warning("Player ID %s does not exist in registry" % player_id)
		return
	var effect_ids = effect_by_player_dict[player_id].keys()
	effect_by_player_dict[player_id].clear()
	for effect_id in effect_ids:
		remove_effect_by_id(effect_id)


func get_effect_descriptions_for_player(pid: int) -> String:
	var result_str = ""
	if not effect_by_player_dict.has(pid):
		return result_str
	for eid in effect_by_player_dict[pid].keys():
		result_str += effect_by_player_dict[pid][eid].get_effect_description() + "\n"
	return result_str

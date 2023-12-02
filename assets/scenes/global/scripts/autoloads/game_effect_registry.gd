extends Node

var effect_dict: Dictionary = {}
var effect_by_player_dict: Dictionary = {}

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


func __get_next_availble_id():
	internal_counter += 1
	return internal_counter


## Adds an effect globally (aka with applier id = 0)
func add_effect_globally(pid_list: Array, effect: GameEffect):
	for pid in pid_list:
		add_effect_to_player(0, pid, effect)


## Adds an effect to a player
func add_effect_to_player(applier_id: int, target_id: int, effect: GameEffect):
	var effect_id = __get_next_availble_id()
	if effect_dict.has(effect_id):
		push_error("Duplicate effect id")
		return
	effect.effect_id = effect_id
	effect.applier_id = applier_id
	effect.target_id = target_id
	effect.activate()
	effect_dict[effect_id] = effect
	if effect_by_player_dict.has(target_id):
		effect_by_player_dict[target_id][effect_id] = effect
	else:
		effect_by_player_dict[target_id] = {effect_id: effect}


## Removes an effect by its id
func remove_effect_by_id(effect_id: int):
	if not effect_dict.has(effect_id):
		push_warning("Effect ID %s does not exist in registry" % effect_id)
		return
	var target_effect: GameEffect = effect_dict[effect_id]
	effect_dict.erase(effect_id)
	effect_by_player_dict[target_effect.target_id].erase(effect_id)
	target_effect.deactivate()


## Removes all effects from a player
func remove_all_effects_from_player(player_id: int):
	if not effect_by_player_dict.has(player_id):
		push_warning("Player ID %s does not exist in registry" % player_id)
		return
	var effect_ids = effect_by_player_dict[player_id].keys()
	effect_by_player_dict[player_id].clear()
	for effect_id in effect_ids:
		remove_effect_by_id(effect_id)

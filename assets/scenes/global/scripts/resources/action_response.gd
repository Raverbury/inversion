class_name ActionResponse

var game_state: GameState
var action_results: Array

var itr = -1

func has_next_result():
	return len(action_results) > (itr + 1)


func get_next_result() -> Array:
	if has_next_result() == false:
		return []
	itr += 1
	var next_result = action_results[itr]
	if not next_result is Array:
		next_result = [next_result]
	return next_result


func _to_string():
	return "%s\n%s" % [game_state, action_results]
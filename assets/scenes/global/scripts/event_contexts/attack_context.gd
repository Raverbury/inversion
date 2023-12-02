class_name AttackContext

var attacker_id: int = -1
var target_mapgrid: Vector2i
var game_state: GameState
var possible_victims: Array = []
var current_target_id: int = -1
var number_of_victims: int = 0
var number_of_hits: int = 0
var number_of_misses: int = 0
var action_results: Array = []
var health_to_lose: int = 0

func _init(atker_id, target, _game_state, _possible_victims, victim_id, _action_results):
	attacker_id = atker_id
	target_mapgrid = target
	game_state = _game_state
	possible_victims = _possible_victims
	current_target_id = victim_id
	action_results = _action_results
	number_of_victims = len(possible_victims)
	number_of_hits = 0
	number_of_misses = 0
	health_to_lose = 0


func get_attacker() -> Player:
	return game_state.player_dict[attacker_id]


func get_target() -> Player:
	return game_state.player_dict[current_target_id]

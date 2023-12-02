class_name GameStartContext

var game_state: GameState
var action_results: Array
var tile_map: GameTileMap

func _init(_gs, _action_results, _tile_map):
	game_state = _gs
	action_results = _action_results
	tile_map = _tile_map

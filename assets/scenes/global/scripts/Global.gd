extends Node

var rng_source = RandomNumberGenerator.new()

func _ready():
	rng_source.seed = int(Time.get_unix_time_from_system())

func get_random_from_list(list):
	var length = len(list)
	return list[rng_source.randi_range(0, length - 1)]

class Set:
	var dic: Dictionary = {}

	func clear():
		dic = {}
	
	func has(item):
		return dic.has(item)
	
	func add(item):
		if has(item):
			return
		dic[item] = 1
	
	func pop(item):
		if has(item):
			dic.erase(item)
		return
	
	func items():
		return dic.keys()

class Constant:
	class Scene:
		const MENU_UI = "res://assets/scenes/menu/menu_ui.tscn"
		const TILE_INFO_UI = "res://assets/scenes/game/tile_info_ui.tscn"
		const CLASS_SELECT_UI = "res://assets/scenes/game/class_select_ui.tscn"

		const GAME_SCENE = "res://assets/scenes/game/game.tscn"

		const MAP_0_SCENE = "res://assets/scenes/game/map_0.tscn"
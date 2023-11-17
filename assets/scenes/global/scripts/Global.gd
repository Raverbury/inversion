extends Node

var rng_source = RandomNumberGenerator.new()

func _ready():
	rng_source.seed = int(Time.get_unix_time_from_system())

func get_random_from_list(list):
	var length = len(list)
	return list[rng_source.randi_range(0, length - 1)]


class Util:
	static func manhantan_distance(mapgrid1: Vector2i, mapgrid2: Vector2i):
		return abs(mapgrid1.x - mapgrid2.x) + abs(mapgrid1.y - mapgrid2.y)


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


class PriorityQueue:
	var arr: Array = []
	var item_dict: Dictionary = {}

	func insert(item, priority):
		arr.insert(__get_insert_pos(priority), [item, priority])
		item_dict[item] = 1


	func pop():
		var tmp = arr.pop_front()[0]
		item_dict.erase(tmp)
		return tmp


	func has(item):
		return item in item_dict


	func __get_insert_pos(priority):
		var insert_pos = 0
		for inner_arr in arr:
			if priority < inner_arr[1]:
				return insert_pos
			else:
				insert_pos += 1
		return insert_pos


	func is_empty():
		return arr.is_empty()


class Constant:
	class Scene:
		const MENU_UI = "res://assets/scenes/menu/menu_ui.tscn"
		const TILE_INFO_UI = "res://assets/scenes/game/tile_info_ui.tscn"
		const CLASS_SELECT_UI = "res://assets/scenes/game/class_select_ui.tscn"
		const TURN_UI = "res://assets/scenes/game/turn_ui.tscn"

		const GAME_SCENE = "res://assets/scenes/game/game.tscn"

		const MAP_0_SCENE = "res://assets/scenes/game/map_0.tscn"


	class Direction:
		const LEFT = 0
		const UP = 1
		const RIGHT = 2
		const DOWN = 3

class PlayerClassData:

	const CLASS_DATA = {
		# cid: name, hp, acc, eva, armor, fp, range, cost, ap, vision, description
		0: ["Sniper", 20, 35, 10, 0, 7, 6, 4, 10, 10, "Long-range attacker with high accuracy"],
		1: ["Scout", 20, 20, 25, 0, 3, 4, 3, 14, 10, "Always on the move and evasive"],
	}

	static func getPlayerGameDataBasedOnClass(class_id):
		var pgd = PlayerGameData.new()
		var obj = CLASS_DATA[class_id]
		pgd.class_id = class_id
		pgd.cls_name = obj[0]
		pgd.current_hp = obj[1]
		pgd.max_hp = obj[1]
		pgd.accuracy = obj[2]
		pgd.evasion = obj[3]
		pgd.armor = obj[4]
		pgd.attack_power = obj[5]
		pgd.attack_range = obj[6]
		pgd.attack_cost = obj[7]
		pgd.max_ap = obj[8]
		pgd.current_ap = obj[8]
		pgd.vision_range = obj[9]
		return pgd

extends Node

var __rng_source = RandomNumberGenerator.new()

func _ready():
	__rng_source.seed = int(Time.get_unix_time_from_system())


class Util:
	static func manhantan_distance(mapgrid1: Vector2i, mapgrid2: Vector2i):
		return abs(mapgrid1.x - mapgrid2.x) + abs(mapgrid1.y - mapgrid2.y)


	static func get_random_from_list(list):
		var length = len(list)
		return list[Global.__rng_source.randi_range(0, length - 1)]


	static func roll_acc_eva_check(hit_rate: float) -> bool:
		var roll = Global.__rng_source.randf_range(0.0, 100.0)
		return hit_rate >= roll


	static func center_global_pos_at(mapgrid_position: Vector2i):
		return mapgrid_position * 32 + Vector2i(16, 16)


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
		const PLAYER_INFO_UI = "res://assets/scenes/game/player_info_ui.tscn"
		const END_TURN_PROMPT_UI = "res://assets/scenes/game/end_turn_prompt_ui.tscn"

		const PLAYER_SPRITE_SCENE = "res://assets/scenes/game/resources/player_sprite.tscn"
		const GAME_SCENE = "res://assets/scenes/game/game.tscn"
		const MAP_0_SCENE = "res://assets/scenes/game/map_0.tscn"


	class Spritesheet:
		static func make_path(doll_name, anim):
			return "res://assets/scenes/game/images/spritesheets/%s/spritesheet_%s_%s.png" % [doll_name, doll_name, anim]


	class Direction:
		const LEFT = 0
		const UP = 1
		const RIGHT = 2
		const DOWN = 3
		const STEP_TO_V2OFFSET = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]


class PlayerClassData:

	const CLASS_DATA = {
		# cid: name, hp, acc, eva, armor, fp, range, cost, ap, vision, description
		0: ["Sniper", 20, 35, 5, 0, 7, 6, 4, 10, 10, "M14", "m14", "Long-range attacker with high accuracy"],
		1: ["Scout", 25, 20, 25, 0, 4, 4, 3, 12, 10, "Desert Eagle", "desert_eagle", "Always on the move and evasive"],
	}

	static func getPlayerGameDataBasedOnClass(class_id) -> PlayerGameData:
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
		pgd.weapon_name = obj[10]
		pgd.doll_name = obj[11]
		return pgd

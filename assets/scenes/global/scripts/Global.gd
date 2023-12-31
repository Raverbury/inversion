extends Node

var __rng_source = RandomNumberGenerator.new()

func _ready():
	__rng_source.seed = int(Time.get_unix_time_from_system())


class Util:
	static func manhantan_distance(mapgrid1: Vector2i, mapgrid2: Vector2i):
		return abs(mapgrid1.x - mapgrid2.x) + abs(mapgrid1.y - mapgrid2.y)


	static func draw_random_passives_for_class(class_id: int, max_passives: int):
		var all_class_passive_pools = Global.PlayerClassData.CLASS_PASSIVES
		if not all_class_passive_pools.has(class_id):
			return []
		var class_passive_pool: Array = all_class_passive_pools[class_id].duplicate()
		var result = []
		for i in range(max_passives):
			if class_passive_pool.is_empty():
				return result
			var draw = Global.Util.get_random_from_list(class_passive_pool, true)
			result.append(draw)
		return result


	static func get_random_from_list(list, remove_afterward = false):
		var length = len(list)
		var random_index = Global.__rng_source.randi_range(0, length - 1)
		var item = list[random_index]
		if remove_afterward == true:
			list.pop_at(random_index)
		return item


	static func roll_float_on_scale_100(hit_rate: float) -> bool:
		var roll = Global.__rng_source.randf_range(0.0, 100.0)
		return hit_rate >= roll


	static func global_coord_at(mapgrid_coordinate: Vector2i):
		return mapgrid_coordinate * 32 + Vector2i(16, 16)


	static func global_pos_at(mapgrid_position: int):
		return mapgrid_position * 32 + 16


	static func format_stat_mod_as_string(value: int):
		return str(value) if value < 0 else ("+%s" % str(value))


	static func calc_hit_rate(attacker: PlayerGameData, victim: PlayerGameData,
		attacker_stat_mods: TileStatBonus, victim_stat_mods: TileStatBonus):
		var distance = Global.Util.manhantan_distance(attacker.mapgrid_position,
			victim.mapgrid_position)
		var ranged_acc_mod = (attacker.ranged_accuracy_modifier[distance] if
			(distance <= attacker.attack_range) else 0.0)
		# out of range then always miss
		if ranged_acc_mod == 0.0:
			return 0.0
		var final_accuracy = (attacker.accuracy + attacker_stat_mods.accuracy_mod)
		final_accuracy = clampf(final_accuracy, 0.0, final_accuracy)
		var final_evasion = victim.evasion + victim_stat_mods.evasion_mod
		final_evasion = clampf(final_evasion, 0.0, final_evasion)
		# cases where both acc and eva are 0 then 50/50
		if final_accuracy + final_evasion == 0.0:
			return 50.0
		# if only eva is 0 then always hit
		if final_evasion == 0:
			return 100.0
		var hit_rate = ((float(final_accuracy) * ranged_acc_mod) /
			float(final_accuracy + final_evasion)) * 100.0
		hit_rate = clampf(hit_rate, 5.0, 100.0)
		return hit_rate


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
		const TURN_TIMER_UI = "res://assets/scenes/game/turn_timer_ui.tscn"

		const PLAYER_SPRITE_SCENE = "res://assets/scenes/game/resources/player_sprite.tscn"
		const GAME_SCENE = "res://assets/scenes/game/game.tscn"
		const MAP_0_SCENE = "res://assets/scenes/game/map_0.tscn"
		const MAP_POOL = ["res://assets/scenes/game/maps/mapv2_grassy_field.tscn"]


	class Spritesheet:

		static func make_path(doll_name, anim):
			return "res://assets/scenes/game/images/spritesheets/%s/spritesheet_%s_%s.png" % [doll_name, doll_name, anim]


	class Direction:

		const LEFT = 0
		const UP = 1
		const RIGHT = 2
		const DOWN = 3
		const STEP_TO_V2OFFSET = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]


	class Misc:

		const CHAT_COLOR = [Color.SKY_BLUE, Color.DARK_SEA_GREEN, Color.LIGHT_PINK, Color.LIGHT_SALMON]

		const SCREEN_EDGE_PAN_MARGIN = 60

		const TURN_TIMER_DURATION = 75


class PlayerClassData:

	const CLASS_DATA = {
		# cid: name,    hp, acc, eva, armor, fp, cost, ap, vision,
		# ranged acc mod, weapon name, doll id, description
		0: ["Sniper",   20, 35,  10,  0,     7,  4,    12, 10,
			[0.8, 0.8, 0.8, 0.8, 1.0, 1.0, 1.0, 1.8, 1.8, 1.8, 1.8, 1.0], # range of 11
			"M14", "m14", "Long-range attacker with high accuracy"],
		1: ["Scout",    26, 15,  30,  0,     4,  3,    18, 10,
			[1.5, 1.5, 1.5, 1.5, 1.5, 1.0], # range of 5
			"Colt Python", "python", "Always on the move and evasive"],
		2: ["Vanguard", 33, 13,  -10, 2,     5,  4,    12, 10,
			[1.7, 1.7, 1.7, 1.0, 0.3], # range of 4
			"Winchester M1887", "m1887", "Armored and devastating with point-blank blasts"],
		3: ["Assault",  26, 22,  15,  0,     5,  2,    13, 10,
			[1.5, 1.5, 1.5, 1.5, 1.0, 1.0, 1.0, 0.8], # range of 7
			"Zastava M21", "zas_m21", "Stock standard all-rounder"],
	}

	static var CLASS_PASSIVES = {
		0: [HappyCamperEffect, FocusShotEffect],
		1: [NomadEffect, IncendiaryRoundEffect],
		2: [PerseveranceEffect, BerserkEffect],
		3: [StabilizedAimEffect, DisciplinedShootingEffect]
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
		pgd.attack_range = len(obj[9]) - 1
		pgd.attack_cost = obj[6]
		pgd.max_ap = obj[7]
		pgd.current_ap = obj[7]
		pgd.vision_range = obj[8]
		pgd.ranged_accuracy_modifier = obj[9]
		pgd.weapon_name = obj[10]
		pgd.doll_name = obj[11]
		return pgd

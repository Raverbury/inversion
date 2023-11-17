extends Node2D

var game_state: GameState

var tile_map: GameTileMap = null
var make_path_last_cell: Vector2i
var make_path_has_last_cell: bool = false
var cached_reachables: Array = []
var cached_attackables: Array = []

var is_loading_map_scene: bool = false
var map_scene_path: String

enum ACTION_MODE {MOVE_MODE, ATTACK_MODE, VIEW_MODE}
var current_action_mode = ACTION_MODE.VIEW_MODE

var current_move_path = []
var current_path_cost = 0

func _ready():
	EventBus.game_started.connect(__game_started_handler)


func _exit_tree():
	EventBus.class_select_ui_freed.emit()
	EventBus.tile_info_ui_freed.emit()
	EventBus.turn_ui_freed.emit()

func load_map(scene_path):
	ResourceLoader.load_threaded_request(scene_path)
	map_scene_path = scene_path
	is_loading_map_scene = true


func __resolve_load_map():
	if is_loading_map_scene == false:
		return
	if ResourceLoader.load_threaded_get_status(map_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	if ResourceLoader.load_threaded_get_status(map_scene_path) != ResourceLoader.THREAD_LOAD_LOADED:
		print("ERROR loading resources")
		is_loading_map_scene = false
		return
	var map_scene = ResourceLoader.load_threaded_get(map_scene_path) as PackedScene
	tile_map = map_scene.instantiate()
	add_child(tile_map)
	move_child(tile_map, 0)
	is_loading_map_scene = false
	Main.add_ui(Global.Constant.Scene.CLASS_SELECT_UI, 0)
	Main.add_ui(Global.Constant.Scene.TILE_INFO_UI, 0)
	Main.add_ui(Global.Constant.Scene.TURN_UI, 0)
	# print(a_star(Vector2(-3, 2), Vector2(-2, -4)))


func _process(_delta):
	__resolve_load_map()


func _input(event):
	if tile_map == null:
		return
	__get_tile_data(event)
	__process_command_mode(event)
	__make_movement_path(event)
	__send_movement_path(event)
	# if event is InputEventMouseMotion:
	# 	# get tm coord/"index" of tile
	# 	var hovered_cell: Vector2i = tile_map.local_to_map(get_global_mouse_position())
	# 	# get source id in tileset of said tile
	# 	var tss_id: int = tile_map.get_cell_source_id(0, hovered_cell)
	# 	# if not empty
	# 	if tss_id != -1:
	# 		# add select tile to tm layer 2
	# 		tile_map.set_cell(2, hovered_cell, 2, Vector2i(0, 0))
	# 		# when mouse leave tile basically
	# 		# remove select tile on tm layer 2
	# 		if make_path_has_last_cell == true && hovered_cell != make_path_last_cell:
	# 			tile_map.set_cell(2, make_path_last_cell, -1, tile_map.get_cell_atlas_coords(0, make_path_last_cell))
	# 			self.highlight_tiles(self.cached_reachables, false)
	# 			# self.highlight_tiles(self.cached_attackables, false)
	# 		if make_path_has_last_cell == false || hovered_cell != make_path_last_cell:
	# 			# grab td
	# 			var tile_data: TileData = tile_map.get_cell_tile_data(0, hovered_cell)
	# 			# send info of td to ui
	# 			var texture = tile_map.tile_set.get_source(0).texture
	# 			var atlas_coord = tile_map.get_cell_atlas_coords(0, hovered_cell) as Vector2
	# 			var tile_name = tile_data.get_custom_data("name")
	# 			var tile_desc = tile_data.get_custom_data("description")
	# 			EventBus.game_tile_hovered.emit(texture, atlas_coord, tile_name, tile_desc)
	# 			self.cached_reachables = self.get_reachable_tiles(hovered_cell, 2)
	# 			self.highlight_tiles(self.cached_reachables, true)
	# 			# self.cached_attackables = self.get_attackable_tiles(hovered_cell, 7)
	# 			# self.highlight_tiles(self.cached_attackables, true)
	# 		# save current cell info to check against when "leaving"
	# 		make_path_last_cell = hovered_cell
	# 		make_path_has_last_cell = true


func __process_command_mode(event: InputEvent):
	if not __is_my_turn():
		return
	if event.is_action_released("move_command"):
		if current_action_mode == ACTION_MODE.MOVE_MODE:
			current_action_mode = ACTION_MODE.VIEW_MODE
			tile_map.hide_reachables()
			tile_map.hide_movement_path()
			make_path_has_last_cell = false
			current_move_path = []
			current_path_cost = 0
		else:
			current_action_mode = ACTION_MODE.MOVE_MODE
			tile_map.show_reachables()


func __get_tile_data(event: InputEvent):
	if event is InputEventMouseMotion:
		var hovered_cell: Vector2i = tile_map.local_to_map(tile_map.to_local(get_global_mouse_position()))
		tile_map.select_tile(hovered_cell)
		var texture = tile_map.tile_set.get_source(0).texture
		var atlas_coord = tile_map.get_cell_atlas_coords(0, hovered_cell) as Vector2
		var tile_name = tile_map.get_data_at(hovered_cell, "name", "...")
		var tile_desc = tile_map.get_data_at(hovered_cell, "description", "...")
		var ap_cost = tile_map.get_data_at(hovered_cell, "ap_cost", -1)
		var acc_mod = tile_map.get_data_at(hovered_cell, "accuracy_mod", 0)
		var eva_mod = tile_map.get_data_at(hovered_cell, "evasion_mod", 0)
		var armor_mod = tile_map.get_data_at(hovered_cell, "armor_mod", 0)
		EventBus.game_tile_hovered.emit(texture, atlas_coord, tile_name, tile_desc, ap_cost, acc_mod, eva_mod, armor_mod)


func __make_movement_path(event: InputEvent):
	if not __is_my_turn():
		return
	if current_action_mode != ACTION_MODE.MOVE_MODE:
		return
	if not event is InputEventMouseMotion:
		return
	var hovered_cell: Vector2i = tile_map.local_to_map(tile_map.to_local(get_global_mouse_position()))
	if make_path_has_last_cell == true and make_path_last_cell == hovered_cell:
		return
	make_path_last_cell = hovered_cell
	make_path_has_last_cell = true
	var player_mapgrid_pos = __get_my_player().player_game_data.mapgrid_position
	var player_current_ap = __get_my_player().player_game_data.current_ap
	# drop everything after hovered cell if reselected
	if hovered_cell in current_move_path:
		current_move_path = current_move_path.slice(0, current_move_path.find(hovered_cell) + 1)
		current_path_cost = __get_path_cost()
		tile_map.set_movement_path(current_move_path, current_path_cost > player_current_ap)
		tile_map.show_movement_path()
		return
	# if neighbor to last cell in path (current pos if empty), check ap cost and add to path
	var last_cell_in_path = player_mapgrid_pos if current_move_path.is_empty() else current_move_path.back()
	if __tiles_are_neighbor(last_cell_in_path, hovered_cell):
		var cell_ap_cost = tile_map.get_ap_cost_at(hovered_cell)
		if player_mapgrid_pos == hovered_cell or cell_ap_cost == -1 or not hovered_cell in cached_reachables:
			current_move_path = []
			current_path_cost = 0
			tile_map.set_movement_path(current_move_path, current_path_cost > player_current_ap)
			tile_map.show_movement_path()
			return
		current_move_path.append(hovered_cell)
		current_path_cost = __get_path_cost()
		tile_map.set_movement_path(current_move_path, current_path_cost > player_current_ap)
		tile_map.show_movement_path()
	else:
		current_move_path = a_star(__get_my_player().player_game_data.mapgrid_position, hovered_cell).slice(1)
		current_path_cost = __get_path_cost()
		tile_map.set_movement_path(current_move_path, current_path_cost > player_current_ap)
		tile_map.show_movement_path()


func __send_movement_path(event: InputEvent):
	if not __is_my_turn():
		return
	if current_action_mode != ACTION_MODE.MOVE_MODE:
		return
	if event.is_action_released("mouse_1"):
		var current_ap = __get_my_player().player_game_data.current_ap
		if not __validate_path() or current_path_cost > current_ap:
			return
		print(__make_steps_from_path())


func __make_steps_from_path():
	var current_mapgrid_pos = __get_my_player().player_game_data.mapgrid_position
	var tmp_move_path = [current_mapgrid_pos]
	tmp_move_path.append_array(current_move_path)
	var move_steps = []
	var offset_step_map = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]
	for i in range(len(tmp_move_path) - 1):
		var tile1 = tmp_move_path[i]
		var tile2 = tmp_move_path[i + 1]
		var offset = tile2 - tile1
		var step_direction = offset_step_map.find(offset)
		move_steps.append(step_direction)
	return move_steps


func __validate_path():
	if len(current_move_path) <= 0:
		return false
	for i in range(len(current_move_path) - 1):
		var tile1 = current_move_path[i]
		var tile2 = current_move_path[i + 1]
		if not __tiles_are_neighbor(tile1, tile2):
			return false
	return true


func __get_path_cost():
	var path_cost = 0
	for tile in current_move_path:
		path_cost += tile_map.get_ap_cost_at(tile)
	return path_cost


func __tiles_are_neighbor(mapgrid1, mapgrid2):
	return Global.Util.manhantan_distance(mapgrid1, mapgrid2) == 1


func get_ap_cost(coord):
	if self.tile_map == null:
		return -1
	var tss_id: int = tile_map.get_cell_source_id(0, coord)
	if tss_id == -1:
		return -1
	var tile_data: TileData = tile_map.get_cell_tile_data(0, coord)
	return tile_data.get_custom_data("ap_cost")


func get_reachable_tiles(source: Vector2i, ap: int):
	var reachables = Global.Set.new()
	var cache = {}
	var next_tiles = [[Vector2i(source.x - 1, source.y), 2], [Vector2i(source.x, source.y - 1), 3], [Vector2i(source.x + 1, source.y), 0], [Vector2i(source.x, source.y + 1), 1]]
	for next_tile in next_tiles:
		var next_coord = next_tile[0]
		var coming_from = next_tile[1]
		self.traverse(ap, next_coord, reachables, coming_from, cache)
	return reachables.items()


func traverse(ap, coord, reachables, coming_from, cache):
	var ap_cost = get_ap_cost(coord)
	if ap_cost == -1:
		return
	if cache.has(coord):
		if cache[coord] >= ap:
			return
	else:
		cache[coord] = ap
	if ap_cost <= ap:
		ap = ap - ap_cost
		reachables.add(coord)
	else:
		return
	var next_tiles = [[Vector2i(coord.x - 1, coord.y), 2], [Vector2i(coord.x, coord.y - 1), 3], [Vector2i(coord.x + 1, coord.y), 0], [Vector2i(coord.x, coord.y + 1), 1]]
	next_tiles.pop_at(coming_from)
	for next_tile in next_tiles:
		var next_coord = next_tile[0]
		var next_coming_from = next_tile[1]
		self.traverse(ap, next_coord, reachables, next_coming_from, cache)


func highlight_tiles(list_of_coords, do_highlight, highlight_atlas_coord = Vector2i(0, 1)):
	for coord in list_of_coords:
		self.tile_map.set_cell(1, coord, 1 if do_highlight else -1, highlight_atlas_coord)


func get_attackable_tiles(source: Vector2i, attack_range: int): # say range of 3
	var attackables = Global.Set.new()
	for x in range(-attack_range, attack_range + 1): # x is [-3; 3]
		var y_leftover = attack_range - abs(x) # we want y to be 0, 1, 2, 3, 2, 1, 0 given that range of x
		for y in range(-y_leftover, y_leftover + 1):
			var tile_coord = Vector2i(source.x + x, source.y + y)
			attackables.add(tile_coord)
	return attackables.items()


func a_star_h(node_mapgrid: Vector2i, goal_mapgrid: Vector2i):
	return Global.Util.manhantan_distance(node_mapgrid, goal_mapgrid)


func a_star(start_mapgrid: Vector2i, goal_mapgrid: Vector2i):
	if not goal_mapgrid in cached_reachables:
		return []

	var pq: Global.PriorityQueue = Global.PriorityQueue.new()
	var came_from: Dictionary = {}
	var g_score: Dictionary = {} # cheapest cost from start to n

	pq.insert(start_mapgrid, a_star_h(start_mapgrid, goal_mapgrid))
	g_score[start_mapgrid] = 0

	while not pq.is_empty():
		var current_node: Vector2i = pq.pop()
		# print("New loop")
		# print(current_node)
		if current_node == goal_mapgrid:
			var path = [current_node]
			while current_node in came_from.keys():
				current_node = came_from[current_node]
				path.insert(0, current_node)
			return path

		for neighbor_offset in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]:
			var neighbor_node = current_node + neighbor_offset
			if not neighbor_node in cached_reachables:
				continue
			var next_cost = tile_map.get_ap_cost_at(neighbor_node)
			if next_cost == -1:
				continue
			var temp_g_score = g_score[current_node] + next_cost
			if not neighbor_node in g_score.keys() or temp_g_score < g_score[neighbor_node]:
				g_score[neighbor_node] = temp_g_score
				came_from[neighbor_node] = current_node
				if not pq.has(neighbor_node):
					pq.insert(neighbor_node, temp_g_score + a_star_h(neighbor_node, goal_mapgrid))
	return []


func __game_started_handler(_game_state: GameState):
	EventBus.class_select_ui_freed.emit()
	game_state = _game_state
	for pid in game_state.player_dict:
		var player_sprite_ps = load("res://assets/scenes/game/resources/player_sprite_prefab_m14.tscn") as PackedScene
		var player_sprite: GamePlayerSprite = player_sprite_ps.instantiate()
		player_sprite.player_id = pid
		player_sprite.set_mapgrid_pos(game_state.player_dict[pid].player_game_data.mapgrid_position)
		add_child(player_sprite)
	EventBus.camera_panned.emit(Vector2(game_state.player_dict[game_state.turn_of_player].player_game_data.mapgrid_position) * 32 + Vector2(16, 16), 1)
	var my_player: Player = __get_my_player()
	cached_reachables = get_reachable_tiles(my_player.player_game_data.mapgrid_position, my_player.player_game_data.current_ap)
	cached_attackables = get_attackable_tiles(my_player.player_game_data.mapgrid_position, my_player.player_game_data.attack_range)
	tile_map.set_reachables(cached_reachables)
	EventBus.turn_displayed.emit(game_state.player_dict[game_state.turn_of_player].display_name, __is_my_turn(), game_state.turn)


func __get_my_player() -> Player:
	if game_state == null:
		return null
	return game_state.player_dict[Main.root_mp.get_unique_id()]


func __is_my_turn():
	if game_state == null:
		return false
	return game_state.turn_of_player == __get_my_player().peer_id

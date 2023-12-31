extends Node2D

var game_state: GameState : set = __set_game_state

var game_is_initialized: bool = false
var tile_map: GameTileMap = null
var make_path_last_cell: Vector2i
var make_path_has_last_cell: bool = false
var cached_reachables: Array = []
var cached_attackables: Dictionary = {}
var last_attack_target: Vector2i
var has_last_attack_target: bool = false

var is_loading_map_scene: bool = false
var map_scene_path: String

enum ACTION_MODE {MOVE_MODE, ATTACK_MODE, VIEW_MODE}
var current_action_mode = ACTION_MODE.VIEW_MODE

var current_move_path: Array = []
var current_path_cost = 0
var attack_targets: Array = []

var cached_result: GameState.RESULT = GameState.RESULT.ON_GOING
var cached_action_response: ActionResponse

var menu_is_opened: bool = false
var anim_is_playing: bool = false
var is_processing_action_response: bool = false

var do_not_confirm_to_end: bool = false

func _ready():
	EventBus.game_input_enabled.connect(__game_input_enabled_handler)
	EventBus.anim_is_being_played.connect(__anim_is_being_played_handler)
	EventBus.end_turn_confirmed.connect(__end_turn_confirmed_handler)
	EventBus.action_response_received.connect(__action_response_received_handler)
	EventBus.game_resolved.connect(__game_resolved_handler)


func _exit_tree():
	EventBus.class_select_ui_freed.emit()
	EventBus.tile_info_ui_freed.emit()
	EventBus.turn_ui_freed.emit()
	EventBus.player_info_ui_freed.emit()
	EventBus.end_turn_prompt_ui_freed.emit()
	EventBus.turn_timer_ui_freed.emit()


func load_map(scene_path):
	ResourceLoader.load_threaded_request(scene_path)
	map_scene_path = scene_path
	is_loading_map_scene = true


func _process(_delta):
	__resolve_load_map()
	if __should_control_camera() == false:
		return
	if tile_map == null:
		return
	__control_camera()


func _input(event):
	if __should_listen_to_input() == false:
		return
	if tile_map == null:
		return
	__get_tile_data(event)
	__process_command(event)
	__focus_camera_on_player(event)
	__make_movement_path(event)
	__send_movement_path(event)
	__choose_attack_target(event)
	__send_attack_target(event)

#region input processing

func __process_command(event: InputEvent):
	if not __is_my_turn():
		return
	if event.is_action_released("move_command"):
		if current_action_mode == ACTION_MODE.MOVE_MODE:
			__set_action_mode(ACTION_MODE.VIEW_MODE)
		else:
			__set_action_mode(ACTION_MODE.MOVE_MODE)
	elif event.is_action_released("attack_command"):
		if current_action_mode == ACTION_MODE.ATTACK_MODE:
			__set_action_mode(ACTION_MODE.VIEW_MODE)
		else:
			__set_action_mode(ACTION_MODE.ATTACK_MODE)
	elif event.is_action_released("end_command"):
		if do_not_confirm_to_end == false:
			EventBus.end_turn_prompt_showed.emit(__get_my_player().player_game_data.current_ap > 0)
		else:
			__send_end_turn()


func __set_action_mode(new_action_mode: ACTION_MODE):
	current_action_mode = new_action_mode
	if current_action_mode == ACTION_MODE.VIEW_MODE:
		# hide move stuff
		tile_map.hide_reachables()
		tile_map.hide_movement_path()
		make_path_has_last_cell = false
		current_move_path = []
		current_path_cost = 0
		# hide attack stuff
		tile_map.hide_attackables()
		tile_map.hide_attack_target()
		attack_targets = []
		has_last_attack_target = false
		EventBus.ap_cost_updated.emit(0)
	elif current_action_mode == ACTION_MODE.ATTACK_MODE:
		tile_map.hide_reachables()
		tile_map.hide_movement_path()
		make_path_has_last_cell = false
		current_move_path = []
		current_path_cost = 0
		tile_map.show_attackables()
		EventBus.ap_cost_updated.emit(0)
	elif current_action_mode == ACTION_MODE.MOVE_MODE:
		tile_map.hide_attackables()
		tile_map.hide_attack_target()
		attack_targets = []
		has_last_attack_target = false
		tile_map.show_reachables()
		EventBus.ap_cost_updated.emit(0)
	EventBus.mode_updated.emit(current_action_mode)


func __get_tile_data(event: InputEvent):
	if event is InputEventMouseMotion:
		var hovered_cell: Vector2i = tile_map.local_to_map(tile_map.to_local(get_global_mouse_position()))
		tile_map.select_tile(hovered_cell)
		var texture = tile_map.tile_set.get_source(0).texture
		var atlas_coord = tile_map.get_atlas_coord_at(hovered_cell)
		var tile_name = tile_map.get_data_at(hovered_cell, "name", "Hey there")
		var tile_desc = tile_map.get_data_at(hovered_cell, "description", "Plz go back im too lazy to clamp camera")
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
		EventBus.ap_cost_updated.emit(current_path_cost)
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
			EventBus.ap_cost_updated.emit(current_path_cost)
			return
		current_move_path.append(hovered_cell)
		current_path_cost = __get_path_cost()
		tile_map.set_movement_path(current_move_path, current_path_cost > player_current_ap)
		tile_map.show_movement_path()
		EventBus.ap_cost_updated.emit(current_path_cost)
	else:
		current_move_path = a_star(__get_my_player().player_game_data.mapgrid_position, hovered_cell, player_current_ap).slice(1)
		current_path_cost = __get_path_cost()
		tile_map.set_movement_path(current_move_path, current_path_cost > player_current_ap)
		tile_map.show_movement_path()
		EventBus.ap_cost_updated.emit(current_path_cost)


func __send_movement_path(event: InputEvent):
	if not __is_my_turn():
		return
	if current_action_mode != ACTION_MODE.MOVE_MODE:
		return
	if event.is_action_released("mouse_1"):
		var current_ap = __get_my_player().player_game_data.current_ap
		if not __validate_path() or current_path_cost > current_ap:
			return
		var move_steps = __make_steps_from_path()
		Rpc.player_request_move.rpc_id(1, SRLZ.serialize(PlayerMoveRequestMessage.new(move_steps)))
		__set_action_mode(ACTION_MODE.VIEW_MODE)


func __make_steps_from_path():
	var current_mapgrid_pos = __get_my_player().player_game_data.mapgrid_position
	var tmp_move_path = [current_mapgrid_pos]
	tmp_move_path.append_array(current_move_path)
	var move_steps = []
	var offset_step_map = Global.Constant.Direction.STEP_TO_V2OFFSET
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


func __choose_attack_target(event: InputEvent):
	if not __is_my_turn():
		return
	if current_action_mode != ACTION_MODE.ATTACK_MODE:
		return
	if not event is InputEventMouseMotion:
		return
	var hovered_cell: Vector2i = tile_map.local_to_map(tile_map.to_local(get_global_mouse_position()))
	if has_last_attack_target == true and attack_targets[0] == hovered_cell:
		return
	last_attack_target = hovered_cell
	has_last_attack_target = true
	attack_targets = [hovered_cell]
	var player_attack_cost = __get_my_player().player_game_data.attack_cost
	var player_current_ap = __get_my_player().player_game_data.current_ap

	if not hovered_cell in cached_attackables.keys():
		attack_targets = []
		has_last_attack_target = false
		tile_map.set_attack_target(attack_targets, player_attack_cost > player_current_ap)
		tile_map.show_attack_target()
		EventBus.ap_cost_updated.emit(0)
		return
	tile_map.set_attack_target(attack_targets, player_attack_cost > player_current_ap)
	tile_map.show_attack_target()
	EventBus.ap_cost_updated.emit(player_attack_cost)


func __send_attack_target(event: InputEvent):
	if not __is_my_turn():
		return
	if current_action_mode != ACTION_MODE.ATTACK_MODE:
		return
	if event.is_action_released("mouse_1"):
		var current_ap = __get_my_player().player_game_data.current_ap
		var attack_cost = __get_my_player().player_game_data.attack_cost
		if has_last_attack_target == false or attack_cost > current_ap or len(attack_targets) == 0 or not attack_targets[0] in cached_attackables.keys():
			return
		Rpc.player_request_attack.rpc_id(1, SRLZ.serialize(PlayerAttackRequestMessage.new(attack_targets[0])))
		__set_action_mode(ACTION_MODE.VIEW_MODE)


func __focus_camera_on_player(event: InputEvent):
	if event.is_action_released("space_bar"):
		__inner_focus_camera(__get_my_player().peer_id if __get_my_player() != null else -1)
	elif event.is_action_released("num_row_1"):
		__inner_focus_camera(__get_pid_at_player_dict_index(0))
	elif event.is_action_released("num_row_2"):
		__inner_focus_camera(__get_pid_at_player_dict_index(1))
	elif event.is_action_released("num_row_3"):
		__inner_focus_camera(__get_pid_at_player_dict_index(2))
	elif event.is_action_released("num_row_4"):
		__inner_focus_camera(__get_pid_at_player_dict_index(3))


func __get_pid_at_player_dict_index(index: int):
	if game_state == null:
		return -1
	if index >= len(game_state.player_dict.keys()):
		return -1
	return game_state.player_dict.keys()[index]


func __inner_focus_camera(pid: int):
	if pid == -1:
		return
	var target = game_state.player_dict[pid].player_game_data.mapgrid_position
	EventBus.camera_force_panned.emit(Global.Util.global_coord_at(target), 0.0)


func __control_camera():
	# pan camera
	var pan_direction = Vector2.ZERO
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var margin = Global.Constant.Misc.SCREEN_EDGE_PAN_MARGIN
	pan_direction.x = -1 if mouse_pos.x <= margin else (1 if mouse_pos.x >= (viewport_size.x - margin) else 0)
	pan_direction.y = -1 if mouse_pos.y <= margin else (1 if mouse_pos.y >= (viewport_size.y - margin) else 0)
	if pan_direction != Vector2.ZERO:
		EventBus.camera_panned.emit(pan_direction)

	# zoom camera
	var zoom_direction = 1 if Input.is_action_just_released("scroll_up") else (-1 if Input.is_action_just_pressed("scroll_down") else 0)
	if zoom_direction != 0:
		EventBus.camera_zoomed.emit(zoom_direction)

#endregion

#region internal processing and algo

func __should_listen_to_input() -> bool:
	return not (menu_is_opened or anim_is_playing or cached_result != GameState.RESULT.ON_GOING)


func __should_control_camera() -> bool:
	return not (menu_is_opened)


func __resolve_load_map():
	if is_loading_map_scene == false:
		return
	if ResourceLoader.load_threaded_get_status(map_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	if ResourceLoader.load_threaded_get_status(map_scene_path) != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("error loading resources")
		is_loading_map_scene = false
		return
	var map_scene = ResourceLoader.load_threaded_get(map_scene_path) as PackedScene
	tile_map = map_scene.instantiate()
	add_child(tile_map)
	move_child(tile_map, 0)
	is_loading_map_scene = false
	Main.add_ui(Global.Constant.Scene.END_TURN_PROMPT_UI, 0)
	Main.add_ui(Global.Constant.Scene.CLASS_SELECT_UI, 0)
	Main.add_ui(Global.Constant.Scene.TURN_TIMER_UI, 0)
	Main.add_ui(Global.Constant.Scene.TILE_INFO_UI, 0)
	Main.add_ui(Global.Constant.Scene.TURN_UI, 0)
	Main.add_ui(Global.Constant.Scene.PLAYER_INFO_UI, 0)
	EventBus.camera_bounds_updated.emit(tile_map.max_x_mapgrid, tile_map.min_x_mapgrid, tile_map.max_y_mapgrid, tile_map.min_y_mapgrid)


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
	var ap_cost = tile_map.get_ap_cost_at(coord)
	if ap_cost == -1:
		return
	if cache.has(coord):
		if cache[coord] >= ap:
			return
		else:
			cache[coord] = ap
	else:
		cache[coord] = ap
	if ap_cost <= ap:
		ap = ap - ap_cost
		reachables.add(coord)
	else:
		return
	if ap <= 0:
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


func get_attackable_tiles(source: Vector2i, attack_range: int, _ap: int, _attack_cost: int): # say range of 3
	var attackables = {}
	for x in range(-attack_range, attack_range + 1): # x is [-3; 3]
		var y_leftover = attack_range - abs(x) # we want y to be 0, 1, 2, 3, 2, 1, 0 given that range of x
		for y in range(-y_leftover, y_leftover + 1):
			var tile_coord = Vector2i(source.x + x, source.y + y)
			var manhantan_distance = abs(x) + abs(y)
			var ranged_acc_mod = __get_my_player().player_game_data.ranged_accuracy_modifier[manhantan_distance]
			attackables[tile_coord] = ranged_acc_mod
	return attackables


func a_star_h(node_mapgrid: Vector2i, goal_mapgrid: Vector2i):
	return Global.Util.manhantan_distance(node_mapgrid, goal_mapgrid)


func a_star(start_mapgrid: Vector2i, goal_mapgrid: Vector2i, current_ap: int):
	if not goal_mapgrid in cached_reachables:
		return []

	var pq: Global.PriorityQueue = Global.PriorityQueue.new()
	var came_from: Dictionary = {}
	var g_score: Dictionary = {} # cheapest cost from start to n

	pq.insert(start_mapgrid, a_star_h(start_mapgrid, goal_mapgrid))
	g_score[start_mapgrid] = 0

	while not pq.is_empty():
		var current_node: Vector2i = pq.pop()
		if current_node == goal_mapgrid:
			var path = [current_node]
			while current_node in came_from.keys():
				current_node = came_from[current_node]
				path.insert(0, current_node)
			return path

		for neighbor_offset in Global.Constant.Direction.STEP_TO_V2OFFSET:
			var neighbor_node = current_node + neighbor_offset
			if not neighbor_node in cached_reachables:
				continue
			var next_cost = tile_map.get_ap_cost_at(neighbor_node)
			if next_cost == -1:
				continue
			var temp_g_score = g_score[current_node] + next_cost
			if (not neighbor_node in g_score.keys() or temp_g_score < g_score[neighbor_node]) and temp_g_score <= current_ap:
				g_score[neighbor_node] = temp_g_score
				came_from[neighbor_node] = current_node
				if not pq.has(neighbor_node):
					pq.insert(neighbor_node, temp_g_score + a_star_h(neighbor_node, goal_mapgrid))
	return []


func __process_next_action_result():
	var action_results = cached_action_response.get_next_result()
	# done
	if action_results.is_empty():
		is_processing_action_response = false
		return
	var index: int = 0
	var max_index = len(action_results) - 1
	print(action_results)
	for _action_result in action_results:
		# nice type hint hack lmao
		var action_result: ActionResult = _action_result
		# check for finished signal from last result only
		if index == max_index:
			action_result.finished.connect(__process_next_action_result)
		action_result.show()
	# do as above instead of calling process next here to wait for anim


func __get_my_player() -> Player:
	if game_state == null:
		return null
	return game_state.player_dict[Main.root_mp.get_unique_id()]


func __is_my_turn():
	if game_state == null:
		return false
	return game_state.turn_of_player == __get_my_player().peer_id


func __set_game_state(_game_state: GameState):
	game_state = _game_state

	# recalculate client highlight stuff
	var my_player: Player = __get_my_player()
	cached_reachables = get_reachable_tiles(my_player.player_game_data.mapgrid_position, my_player.player_game_data.current_ap)
	cached_attackables = get_attackable_tiles(my_player.player_game_data.mapgrid_position, my_player.player_game_data.attack_range,
		my_player.player_game_data.current_ap, my_player.player_game_data.attack_cost)
	tile_map.set_reachables(cached_reachables)
	tile_map.set_attackables(cached_attackables)

	# update ui-esque tuff
	EventBus.player_info_updated.emit(__get_my_player(), tile_map.get_stat_mods_at(__get_my_player().player_game_data.mapgrid_position))
	EventBus.turn_color_updated.emit(game_state.turn_of_player)
	for pid in game_state.player_dict.keys():
		var tooltip_text = __get_tooltip_stats_for_player(pid)
		EventBus.tooltip_updated.emit(pid, tooltip_text)


func __get_tooltip_stats_for_player(pid: int):
	if game_state == null:
		return ""
	# if __get_my_player().peer_id == pid:
	# 	return ""
	var player: Player = game_state.player_dict[pid]
	var pgd: PlayerGameData = player.player_game_data
	var their_stat_mods = tile_map.get_stat_mods_at(pgd.mapgrid_position)
	var my_stat_mods = tile_map.get_stat_mods_at(__get_my_player().player_game_data.mapgrid_position)
	var result: String = (
		("%s %s (%s)\n" % [pgd.cls_name, player.display_name, player.peer_id]) +
		("HP: %s/%s    " % [pgd.current_hp, pgd.max_hp]) +
		("AP: %s/%s\n" % [pgd.current_ap, pgd.max_ap]) +
		("ACC: %s (%s)    " % [pgd.accuracy, Global.Util.format_stat_mod_as_string(their_stat_mods.accuracy_mod)]) +
		("EVA: %s (%s)\n" % [pgd.evasion, Global.Util.format_stat_mod_as_string(their_stat_mods.evasion_mod)]) +
		("Armor: %s (%s)    " % [pgd.armor, Global.Util.format_stat_mod_as_string(their_stat_mods.armor_mod)]) +
		("Attack power: %s\n" % pgd.attack_power) +
		("Attack range: %s    " % pgd.attack_range) +
		("Attack cost: %s\n" % pgd.attack_cost) +
		("Vision range: %s    " % pgd.vision_range) +
		("Hit rate: %.2f%%\n" % Global.Util.calc_hit_rate(__get_my_player().player_game_data,
			pgd, my_stat_mods, their_stat_mods)) +
		("<<<Active effects>>>\n") +
		("%s" % pgd.effect_descriptions)
	)
	return result


func __send_end_turn():
	__set_action_mode(ACTION_MODE.VIEW_MODE)
	Rpc.player_request_end_turn.rpc_id(1)

#endregion

#region event listeners

func __game_setup(_game_state: GameState):
	if game_is_initialized == true:
		return
	EventBus.class_select_ui_freed.emit()
	for pid in _game_state.player_dict:
		var player_sprite_ps = load(Global.Constant.Scene.PLAYER_SPRITE_SCENE) as PackedScene
		var player_sprite: GamePlayerSprite = player_sprite_ps.instantiate()
		player_sprite.doll_name = _game_state.player_dict[pid].player_game_data.doll_name
		player_sprite.player_id = pid
		player_sprite.display_name = _game_state.player_dict[pid].display_name
		player_sprite.set_mapgrid_pos(_game_state.player_dict[pid].player_game_data.mapgrid_position)
		player_sprite.is_me = pid == Main.root_mp.get_unique_id()
		add_child(player_sprite)
	game_is_initialized = true


func __game_input_enabled_handler(value: bool):
	menu_is_opened = value


func __anim_is_being_played_handler(value: bool):
	anim_is_playing = value


func __end_turn_confirmed_handler(do_not_remind: bool):
	do_not_confirm_to_end = do_not_remind
	__send_end_turn()


func __action_response_received_handler(action_response: ActionResponse):
	__game_setup(action_response.game_state)
	game_state = action_response.game_state
	cached_action_response = action_response
	print(action_response)
	is_processing_action_response = true
	__set_action_mode(ACTION_MODE.VIEW_MODE)
	__process_next_action_result()


func __game_resolved_handler(result: GameState.RESULT, _alive):
	cached_result = result

#endregion

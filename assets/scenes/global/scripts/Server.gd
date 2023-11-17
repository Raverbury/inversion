extends Node

var player_dict: Dictionary = {}
var is_initialized = false
var room_is_ready = false

var game_state: GameState

var MAP_PATHS = [Global.Constant.Scene.MAP_0_SCENE]

var server_tile_map: GameTileMap
var map_scene_path: String
var is_loading_map_scene: bool = false

func wipe():
	if is_initialized == false:
		return
	player_dict = {}
	is_initialized = false
	EventBus.player_list_updated.emit(player_dict)


func initialize():
	if is_initialized == true:
		return
	is_initialized = true
	player_dict = {}


func add_player(pid, display_name):
	player_dict[pid] = Player.new(pid, display_name)
	Rpc.update_player_list.rpc(serialize_player_dict())
	check_room_readiness()


func player_set_class(pid, class_id):
	var player: Player = player_dict[pid]
	# no reselect xd
	if player.player_game_data != null:
		return
	player.player_game_data = Global.PlayerClassData.getPlayerGameDataBasedOnClass(class_id)
	player_dict[pid] = player
	print(player_dict)
	if all_players_picked_class() == true:
		game_state = GameState.new(player_dict, server_tile_map.spawn_points)
		game_state.advance_turn()
		Rpc.game_start.rpc(SRLZ.serialize(GameStartMessage.new(game_state)))


func remove_player(pid):
	var player: Player = player_dict[pid] if player_dict.has(pid) else null
	var dn = player.display_name if player != null else "nil"
	player_dict.erase(pid)
	Rpc.update_player_list.rpc(serialize_player_dict())
	check_room_readiness()
	return dn


func player_set_ready(pid, readiness):
	player_dict[pid].is_ready = readiness
	Rpc.update_player_list.rpc(serialize_player_dict())
	check_room_readiness()


func check_room_readiness():
	for pid in player_dict:
		if player_dict[pid].is_ready == false:
			room_is_ready = false
			return
	room_is_ready = true


func all_players_picked_class():
	for k in player_dict:
		if player_dict[k].player_game_data == null:
			return false
	return true


func request_start_room():
	if room_is_ready:
		var map_name = Global.get_random_from_list(MAP_PATHS)
		load_map(map_name)
		Rpc.room_start.rpc(SRLZ.serialize(RoomStartMessage.new(map_name)))


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
	server_tile_map = map_scene.instantiate()
	server_tile_map.set_visible(false)
	is_loading_map_scene = false


func _process(_delta):
	__resolve_load_map()


func serialize_player_dict():
	var message: PlayerListUpdateMessage = PlayerListUpdateMessage.new(player_dict)
	return SRLZ.serialize(message)


func process_player_move_request(pid, move_steps: Array):
	print("Here")
	var player: Player = game_state.player_dict[pid]
	var step_to_mapgrid_offset = Global.Constant.Direction.STEP_TO_V2OFFSET
	for step in move_steps:
		var next_cell = player.player_game_data.mapgrid_position + step_to_mapgrid_offset[step]
		var ap_cost = server_tile_map.get_ap_cost_at(next_cell, -1)
		if ap_cost == -1 or ap_cost > player.player_game_data.current_ap:
			print("YO WTF STOP HOW TF")
		player.player_game_data.current_ap -= ap_cost
		player.player_game_data.mapgrid_position = next_cell
	Rpc.player_move_update(SRLZ.serialize(PlayerMoveResponseMessage.new(pid, move_steps, game_state)))
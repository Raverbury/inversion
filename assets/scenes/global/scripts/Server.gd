extends Node

var player_dict: Dictionary = {}
var is_initialized = false
var room_is_ready = false

var game_state: GameState

var MAP_PATHS = [Global.Constant.Scene.MAP_0_SCENE]

var server_tile_map: GameTileMap
var map_scene_path: String
var is_loading_map_scene: bool = false

var is_in_game: bool = false

func wipe():
	if is_initialized == false:
		return
	player_dict = {}
	is_initialized = false
	is_in_game = false
	EventBus.player_list_updated.emit(player_dict)


func initialize():
	if is_initialized == true:
		return
	is_initialized = true
	player_dict = {}
	is_in_game = false


func add_player(pid, display_name):
	if is_in_game == true:
		Main.root_mp.multiplayer_peer.disconnect_peer(pid)
		return
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
		is_in_game = true
		var map_name = Global.Util.get_random_from_list(MAP_PATHS)
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
	var player: Player = game_state.player_dict[pid]
	var step_to_mapgrid_offset = Global.Constant.Direction.STEP_TO_V2OFFSET
	for step in move_steps:
		var next_cell = player.player_game_data.mapgrid_position + step_to_mapgrid_offset[step]
		var ap_cost = server_tile_map.get_ap_cost_at(next_cell, -1)
		if ap_cost == -1 or ap_cost > player.player_game_data.current_ap:
			print("YO WTF STOP HOW TF CHEAATER CONFIRMED OMG NICE GAME")
		player.player_game_data.current_ap -= ap_cost
		player.player_game_data.mapgrid_position = next_cell
	Rpc.player_move_update.rpc(SRLZ.serialize(PlayerMoveResponseMessage.new(pid, move_steps, game_state)))


func process_player_attack_request(attacker_id, target_mapgrid: Vector2i):
	var attacked_players = []
	var attacker: Player = game_state.player_dict[attacker_id]

	# validation
	var attacker_attack_range = attacker.player_game_data.attack_range
	var attacker_attack_cost = attacker.player_game_data.attack_cost
	var attacker_mapgrid_position = attacker.player_game_data.mapgrid_position

	if attacker_attack_cost > attacker.player_game_data.current_ap:
		print("AYO WTF HACKER111")
	if Global.Util.manhantan_distance(target_mapgrid, attacker_mapgrid_position) > attacker_attack_range:
		print("AYO WTF HACKER222")

	# get list of players at targeted mapgrid excluding self
	for pid in game_state.player_dict.keys():
		if pid == attacker_id:
			continue
		var player: Player = game_state.player_dict[pid]
		if player.player_game_data.mapgrid_position == target_mapgrid:
			attacked_players.append(player)

	# dmg calculation
	var victim_dict: Dictionary = {}
	var attacker_attack_power = attacker.player_game_data.attack_power
	var attacker_mod_stats = server_tile_map.get_stat_mods_at(attacker_mapgrid_position)
	var final_attacker_accuracy = attacker.player_game_data.accuracy + attacker_mod_stats["accuracy_mod"]
	for victim in attacked_players:
		var victim_mod_stats = server_tile_map.get_stat_mods_at(target_mapgrid)
		var final_victim_evasion = victim.player_game_data.evasion + victim_mod_stats["evasion_mod"]
		var final_victim_armor = victim.player_game_data.armor + victim_mod_stats["armor_mod"]
		var hit_rate: float = (float(final_attacker_accuracy) / float(final_attacker_accuracy + final_victim_evasion)) * 100.0
		hit_rate = clampf(hit_rate, 5.0, 100.0)
		var is_attack_a_hit = Global.Util.roll_acc_eva_check(hit_rate)
		victim_dict[victim.peer_id] = [is_attack_a_hit, 0]
		var damage: int = 0
		if is_attack_a_hit == true:
			damage = attacker_attack_power - final_victim_armor
			damage = clamp(damage, 1, victim.player_game_data.current_hp)
			victim.player_game_data.current_hp -= damage
			victim_dict[victim.peer_id][1] = damage
		print("Attacked %s %s, %s%% hit rate" % [victim.display_name, ("for %s damage" % damage)
			if is_attack_a_hit else "and missed", hit_rate])
	attacker.player_game_data.current_ap -= attacker_attack_cost
	print(victim_dict)

	# send attack response
	var message: PlayerAttackResponseMessage = PlayerAttackResponseMessage.new(attacker_id, target_mapgrid, victim_dict, game_state)
	Rpc.player_attack_update.rpc(SRLZ.serialize(message))

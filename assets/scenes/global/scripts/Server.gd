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
	if pid != game_state.turn_of_player:
		print("MOVE TURN HACK")
		return
	var player: Player = game_state.player_dict[pid]
	var step_to_mapgrid_offset = Global.Constant.Direction.STEP_TO_V2OFFSET
	for step in move_steps:
		var next_cell = player.player_game_data.mapgrid_position + step_to_mapgrid_offset[step]
		var ap_cost = server_tile_map.get_ap_cost_at(next_cell, -1)
		if ap_cost == -1 or ap_cost > player.player_game_data.current_ap:
			print("MOVE COST HACK")
		player.player_game_data.current_ap -= ap_cost
		player.player_game_data.mapgrid_position = next_cell
	Rpc.player_move_update.rpc(SRLZ.serialize(PlayerMoveResponseMessage.new(pid, move_steps, game_state)))


func process_player_attack_request(attacker_id, target_mapgrid: Vector2i):
	if attacker_id != game_state.turn_of_player:
		print("ATTACK TURN HACK")
		return
	var attacked_players = []
	var attacker: Player = game_state.player_dict[attacker_id]

	# validation
	var attacker_attack_range = attacker.player_game_data.attack_range
	var attacker_attack_cost = attacker.player_game_data.attack_cost
	var attacker_mapgrid_position = attacker.player_game_data.mapgrid_position

	if attacker_attack_cost > attacker.player_game_data.current_ap:
		print("ATTACK COST HACK")
	if Global.Util.manhantan_distance(target_mapgrid, attacker_mapgrid_position) > attacker_attack_range:
		print("ATTACK RANGE HACK")

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
		var hit_rate: float = Global.Util.calc_hit_rate(final_attacker_accuracy, final_victim_evasion)
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

	# send attack response
	var alive_list = game_state.get_alive_player_list()
	var result: GameState.RESULT
	if len(alive_list) == 0:
		result = GameState.RESULT.DRAW
	elif len(alive_list) == 1 and len(game_state.player_dict.keys()) > 1:
		result = GameState.RESULT.WIN_LOSE
	else:
		result = GameState.RESULT.ON_GOING
	var message: PlayerAttackResponseMessage = PlayerAttackResponseMessage.new(attacker_id,
		target_mapgrid, victim_dict, game_state, result, alive_list)
	Rpc.player_attack_update.rpc(SRLZ.serialize(message))


func process_player_end_turn_request(pid):
	if pid != game_state.turn_of_player:
		print("END TURN HACK")
		return
	game_state.player_end_turn()

	var message: PlayerEndTurnResponseMessage = PlayerEndTurnResponseMessage.new(game_state)
	Rpc.player_end_turn_update.rpc(SRLZ.serialize(message))


func process_player_send_chat_message(pid, display_name, text_message):
	if player_dict == null:
		return
	var pids = player_dict.keys()
	var color = Global.Constant.Misc.CHAT_COLOR[pids.find(pid)]
	var message = PlayerSendChatMessageResponse.new(display_name, text_message, color)
	Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))

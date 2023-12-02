extends Node

var player_dict: Dictionary = {}
var is_initialized = false
var room_is_ready = false

var game_state: GameState

var MAP_POOL = Global.Constant.Scene.MAP_POOL

var server_tile_map: GameTileMap
var map_scene_path: String
var is_loading_map_scene: bool = false

var is_in_game: bool = false

var tween_timer: Tween

var max_number_of_passives: int = 2

var editable_properties = ["max_number_of_passives"]

func _ready():
	EventBus.player_took_damage.connect(__player_take_damage)
	EventBus.player_lost_health.connect(__player_lose_health)
	EventBus.effect_applied_to_player.connect(__apply_effect_to_player)
	EventBus.attack_individual_missed.connect(__player_dodge_attack)
	EventBus.player_healed.connect(__player_healed)
	EventBus.game_started.connect(__game_started)


func wipe():
	if is_initialized == false:
		return
	GameEffectRegistry.clear()
	player_dict = {}
	is_initialized = false
	is_in_game = false
	EventBus.player_list_updated.emit(player_dict)
	if server_tile_map != null:
		server_tile_map.queue_free()
		server_tile_map = null
	__kill_timer()


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
		game_start()


func remove_player(pid):
	var player: Player = player_dict[pid] if player_dict.has(pid) else null
	var dn = player.display_name if player != null else "nil"
	player_dict.erase(pid)
	GameEffectRegistry.remove_all_effects_from_player(pid)
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
		var map_name = Global.Util.get_random_from_list(MAP_POOL)
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
		push_error("error loading resources")
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
	var action_response: ActionResponse = ActionResponse.new()
	var tmp_action_results = []
	var move_context: MoveContext = MoveContext.new(pid, move_steps, game_state, tmp_action_results, server_tile_map)
	if pid != game_state.turn_of_player:
		push_error("MOVE TURN HACK")
		return
	EventBus.movement_declared.emit(move_context)
	var player: Player = game_state.player_dict[pid]
	var step_to_mapgrid_offset = Global.Constant.Direction.STEP_TO_V2OFFSET
	for step in move_steps:
		var next_cell = player.player_game_data.mapgrid_position + step_to_mapgrid_offset[step]
		var ap_cost = server_tile_map.get_ap_cost_at(next_cell, -1)
		if ap_cost == -1 or ap_cost > player.player_game_data.current_ap:
			push_error("MOVE COST HACK")
		EventBus.tile_left.emit(move_context)
		player.player_game_data.current_ap -= ap_cost
		player.player_game_data.mapgrid_position = next_cell
		var mv_result = MoveResult.new().set_stuff(pid, step)
		tmp_action_results.append(mv_result)
		move_context.advance_step()
		EventBus.tile_entered.emit(move_context)
	tmp_action_results.append(EndMoveResult.new().set_stuff(pid))
	EventBus.movement_concluded.emit(move_context)
	action_response.game_state = game_state
	action_response.action_results = tmp_action_results
	send_rpc_action_response(action_response)


func process_player_attack_request(attacker_id, target_mapgrid: Vector2i):
	if attacker_id != game_state.turn_of_player:
		push_error("ATTACK TURN HACK")
		return
	var attacked_players = []
	var attacker: Player = game_state.player_dict[attacker_id]
	var action_response: ActionResponse = ActionResponse.new()
	var tmp_action_results = []

	# validation
	var attacker_attack_range = attacker.player_game_data.attack_range
	var attacker_attack_cost = attacker.player_game_data.attack_cost
	var attacker_mapgrid_position = attacker.player_game_data.mapgrid_position

	if attacker_attack_cost > attacker.player_game_data.current_ap:
		push_error("ATTACK COST HACK")
	if Global.Util.manhantan_distance(target_mapgrid, attacker_mapgrid_position) > attacker_attack_range:
		push_error("ATTACK RANGE HACK")

	tmp_action_results.append(AttackResult.new().set_stuff(attacker_id, target_mapgrid))
	# get list of players at targeted mapgrid excluding self
	for pid in game_state.player_dict.keys():
		if pid == attacker_id:
			continue
		var player: Player = game_state.player_dict[pid]
		if player.player_game_data.mapgrid_position == target_mapgrid:
			attacked_players.append(player)

	var attack_context: AttackContext = AttackContext.new(attacker_id,
		target_mapgrid, game_state, attacked_players, -1, tmp_action_results, server_tile_map)

	EventBus.attack_declared.emit(attack_context)

	# dmg calculation
	var attacker_mod_stats = server_tile_map.get_stat_mods_at(attacker_mapgrid_position)
	for victim in attacked_players:
		attack_context.current_target_id = victim.peer_id
		EventBus.attack_individual_declared.emit(attack_context)
		var victim_mod_stats = server_tile_map.get_stat_mods_at(target_mapgrid)
		var hit_rate: float = Global.Util.calc_hit_rate(attacker.player_game_data, victim.player_game_data,
			attacker_mod_stats, victim_mod_stats)
		var is_attack_a_hit = Global.Util.roll_float_on_scale_100(hit_rate)
		if is_attack_a_hit == true:
			EventBus.attack_individual_hit.emit(attack_context)
			EventBus.player_took_damage.emit(attack_context)
			EventBus.attack_individual_hit_after_damage.emit(attack_context)
		else:
			EventBus.attack_individual_missed.emit(attack_context)
		EventBus.attack_individual_concluded.emit(attack_context)
	attacker.player_game_data.current_ap -= attacker_attack_cost

	# send attack response
	EventBus.attack_concluded.emit(attack_context)
	action_response.game_state = game_state
	action_response.action_results = tmp_action_results
	send_rpc_action_response(action_response)


func process_player_end_turn_request(pid):
	if pid != game_state.turn_of_player:
		push_error("END TURN HACK")
		return

	var action_response: ActionResponse = ActionResponse.new()
	var tmp_action_results = []
	var end_phase_context = EndPhaseContext.new(pid, game_state, tmp_action_results, server_tile_map)

	EventBus.phase_end_declared.emit(end_phase_context)
	var new_turn = game_state.player_end_turn()
	tmp_action_results.append(EndPhaseResult.new().set_stuff(game_state))
	EventBus.phase_end_concluded.emit(end_phase_context)

	if new_turn == true:
		EventBus.turn_ended.emit()

	action_response.game_state = game_state
	action_response.action_results = tmp_action_results

	send_rpc_action_response(action_response)
	__refresh_turn_timer()


func game_start():
	var action_response: ActionResponse = ActionResponse.new()
	var tmp_action_results = []

	var game_start_context = GameStartContext.new(game_state, tmp_action_results, server_tile_map)

	game_state.advance_turn()

	action_response.game_state = game_state
	tmp_action_results.append(EndPhaseResult.new().set_stuff(game_state))
	action_response.action_results = tmp_action_results

	EventBus.game_started.emit(game_start_context)

	send_rpc_action_response(action_response)
	__refresh_turn_timer()


func process_player_send_chat_message(pid, display_name, text_message: String):
	if player_dict == null:
		return
	if text_message == "":
		return
	if text_message.begins_with("/"):
		if pid != 1:
			var message = PlayerSendChatMessageResponse.new("Server", "Insufficient permission, %s (%s)" % [player_dict[pid].display_name, pid], Color.DARK_RED)
			Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))
			return
		var command = text_message.erase(0)
		var args = command.split(" ", false)
		__process_server_command(args)
	else:
		var pids = player_dict.keys()
		var color = Global.Constant.Misc.CHAT_COLOR[pids.find(pid)]
		var message = PlayerSendChatMessageResponse.new(display_name, text_message, color)
		Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))


func __process_server_command(args: Array):
	if args.is_empty():
		var message = PlayerSendChatMessageResponse.new("Server", "Invalid command", Color.DARK_RED)
		Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))
		return
	var command_name = args[0]
	if command_name == "set":
		if args.size() < 3:
			var message = PlayerSendChatMessageResponse.new("Server", "Invalid command", Color.DARK_RED)
			Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))
			return
		var prop_name = args[1]
		var value = args[2]
		if not prop_name in editable_properties:
			var message = PlayerSendChatMessageResponse.new("Server", "Invalid command", Color.DARK_RED)
			Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))
			return
		else:
			set(prop_name, value)
			var message = PlayerSendChatMessageResponse.new("Server", "Set %s to %s" % [prop_name, value], Color.DARK_GREEN)
			Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))
			return
	else:
		var message = PlayerSendChatMessageResponse.new("Server", "Invalid command", Color.DARK_RED)
		Rpc.player_send_chat_message_respond.rpc(SRLZ.serialize(message))
		return


func __check_game_conclusion(action_response: ActionResponse):
	var result: GameState.RESULT
	var alive_list = game_state.get_alive_player_list()
	if len(alive_list) == 0:
		result = GameState.RESULT.DRAW
	elif len(alive_list) == 1 and len(game_state.player_dict.keys()) > 1:
		result = GameState.RESULT.WIN_LOSE
	else:
		result = GameState.RESULT.ON_GOING

	# remove effects from dead players
	var dead_list = game_state.get_dead_player_list()
	for dead_player in dead_list:
		GameEffectRegistry.remove_all_effects_from_player(dead_player.peer_id)
	if result == GameState.RESULT.ON_GOING:
		return
	__kill_timer()
	action_response.action_results.append(GameConcludeResult.new().set_stuff(result, alive_list))


func __kill_timer():
	if tween_timer != null:
		tween_timer.kill()
		tween_timer = null


func __refresh_turn_timer():
	__kill_timer()
	tween_timer = create_tween()
	tween_timer.tween_interval(Global.Constant.Misc.TURN_TIMER_DURATION)
	tween_timer.finished.connect(__turn_timer_timed_out)


func __turn_timer_timed_out():
	tween_timer = null
	process_player_end_turn_request(game_state.turn_of_player)


## Default listener, takes damage before armor mitigation
func __player_take_damage(attack_context: AttackContext):
	var attacker = attack_context.get_attacker()
	var premitigation_damage = attacker.player_game_data.attack_power
	if premitigation_damage <= 0:
		return
	var victim: Player = attack_context.get_target()
	var victim_final_armor = (victim.player_game_data.armor +
		server_tile_map.get_stat_mods_at(victim.player_game_data.mapgrid_position).armor_mod)
	var postmitigation_damage = premitigation_damage - victim_final_armor
	attack_context.health_to_lose = postmitigation_damage
	EventBus.player_lost_health.emit(attack_context)


## Default listener, loses a flat amount of health after armor
func __player_lose_health(attack_context: AttackContext):
	var health_loss = attack_context.health_to_lose
	if health_loss <= 0:
		return
	var victim: Player = attack_context.get_target()
	health_loss = clamp(0, health_loss, victim.player_game_data.current_hp)
	var old_health = victim.player_game_data.current_hp
	victim.player_game_data.current_hp -= health_loss
	var is_dead = victim.player_game_data.current_hp <= 0
	attack_context.action_results.append(PopupFeedbackResult.new().set_stuff_for_take_damage(attack_context.current_target_id, health_loss, is_dead))
	var health_change_context = HealthChangeContext.new(attack_context.current_target_id, attack_context.attacker_id, old_health,
		victim.player_game_data.current_hp, attack_context.game_state, attack_context.action_results, attack_context.tile_map)
	EventBus.player_health_changed.emit(health_change_context)
	if is_dead:
		GameEffectRegistry.remove_all_effects_from_player(attack_context.current_target_id)


## Default listener, dodges an attack
func __player_dodge_attack(attack_context: AttackContext):
	attack_context.action_results.append(PopupFeedbackResult.new().set_stuff_for_miss(attack_context.current_target_id))


## Default listener, creates and adds an effect to reg
func __apply_effect_to_player(applier_id, target_id, effect_class, action_results):
	var effect_instance = effect_class.new(applier_id, target_id, game_state)
	GameEffectRegistry.add_effect_to_player(applier_id, target_id, effect_instance, action_results)


## Default listener, heals player
func __player_healed(heal_context: HealContext):
	var health_gained = heal_context.heal_amount
	if health_gained <= 0:
		return
	var player: Player = heal_context.get_player()
	health_gained = clamp(0, health_gained, player.player_game_data.max_hp - player.player_game_data.current_hp)
	player.player_game_data.current_hp += health_gained
	heal_context.action_results.append(PopupFeedbackResult.new().set_stuff(heal_context.player_id, "+%s" % str(health_gained), Color.GREEN, false))


## Default listener, game started
func __game_started(game_start_context: GameStartContext):
	__apply_class_passive(game_start_context)


func __apply_class_passive(gsc: GameStartContext):
	for _pid in game_state.player_dict.keys():
		var passives_to_apply = Global.Util.draw_random_passives_for_class(
			game_state.player_dict[_pid].player_game_data.class_id, max_number_of_passives)
		for effect_cls in passives_to_apply:
			EventBus.effect_applied_to_player.emit(0, _pid, effect_cls, gsc.action_results)


func send_rpc_action_response(action_response: ActionResponse):
	__check_game_conclusion(action_response)
	for _pid in action_response.game_state.player_dict.keys():
		action_response.game_state.player_dict[_pid].player_game_data.effect_descriptions = GameEffectRegistry.get_effect_descriptions_for_player(_pid)
	Rpc.send_action_response.rpc(SRLZ.serialize(action_response))

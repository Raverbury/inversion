extends Node

var player_dict: Dictionary = {}
var is_initialized = false
var room_is_ready = false

var MAP_PATHS = [Global.Constant.Scene.MAP_0_SCENE]

var map_node: GameTileMap

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
		pass


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


func request_start_game():
	if room_is_ready:
		var map_name = Global.get_random_from_list(MAP_PATHS)
		map_node = load(map_name).instantiate()
		map_node.set_visible(false)
		Rpc.room_start.rpc(SRLZ.serialize(RoomStartMessage.new(map_name)))
		print(map_node.spawn_points)


func serialize_player_dict():
	var message: PlayerListUpdateMessage = PlayerListUpdateMessage.new(player_dict)
	return SRLZ.serialize(message)

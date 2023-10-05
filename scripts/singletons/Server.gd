extends Node

var player_list: Proto.PlayerList
var player_dict: Dictionary = {}
var is_initialized = false
var room_is_ready = false

var MAP_PATHS = ["res://assets/scenes/game/map_0.tscn"]

func wipe():
	if is_initialized == false:
		return
	player_list = Proto.PlayerList.new()
	player_dict = {}
	is_initialized = false
	EventBus.player_list_updated.emit(player_list.to_bytes())

func initialize():
	if is_initialized == true:
		return
	is_initialized = true
	player_list = Proto.PlayerList.new()
	player_dict = {}

func add_player(pid, display_name):
	pid = str(pid)
	var player = Proto.Player.new()
	player.set_peer_id(pid)
	player.set_display_name(display_name)
	player.set_is_ready(false)
	player_dict[pid] = player
	dict_to_player_list()
	Rpc.update_player_list.rpc(player_list.to_bytes())
	check_room_readiness()

func remove_player(pid):
	pid = str(pid)
	var dn = player_dict[pid].get_display_name() if player_dict.has(pid) else "nil"
	player_dict.erase(pid)
	dict_to_player_list()
	Rpc.update_player_list.rpc(player_list.to_bytes())
	check_room_readiness()
	return dn

func player_set_ready(pid, readiness):
	pid = str(pid)
	player_dict[pid].set_is_ready(readiness)
	dict_to_player_list()
	Rpc.update_player_list.rpc(player_list.to_bytes())
	check_room_readiness()

func check_room_readiness():
	for k in player_dict:
		if player_dict[k].get_is_ready() == false:
			room_is_ready = false
			return
	room_is_ready = true

func request_start_game():
	if room_is_ready:
		Rpc.send_ready.rpc(Global.get_random_from_list(MAP_PATHS))

func dict_to_player_list():
	player_list = Proto.PlayerList.new()
	for k in player_dict:
		var player = player_list.add_player_list(k)
		player.set_peer_id(player_dict[k].get_peer_id())
		player.set_is_ready(player_dict[k].get_is_ready())
		player.set_display_name(player_dict[k].get_display_name())

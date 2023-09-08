extends Node

var player_list: Proto.PlayerList
var player_dict: Dictionary = {}
var is_initialized = false

func wipe():
	if is_initialized == false:
		return
	player_list = Proto.PlayerList.new()
	player_dict = {}
	is_initialized = false
	EventBus.player_list_updated.emit(player_list.to_bytes())

func initialize():
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
	Global.update_player_list.rpc(player_list.to_bytes())

func remove_player(pid):
	pid = str(pid)
	var dn = player_dict[pid].get_display_name() if player_dict.has(pid) else "nil"
	player_dict.erase(pid)
	dict_to_player_list()
	Global.update_player_list.rpc(player_list.to_bytes())
	return dn

func player_ready(pid):
	player_dict[pid].set_is_ready(true)
	dict_to_player_list()
	for k in player_dict:
		if player_dict[k].get_is_ready() == false:
			return
	print("All ready")

func dict_to_player_list():
	player_list = Proto.PlayerList.new()
	for k in player_dict:
		var player = player_list.add_player_list(k)
		player.set_peer_id(player_dict[k].get_peer_id())
		player.set_is_ready(player_dict[k].get_is_ready())
		player.set_display_name(player_dict[k].get_display_name())

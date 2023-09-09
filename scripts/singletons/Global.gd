extends Node

@rpc("any_peer", "call_local", "reliable", 0)
func test(data):
	print(get_tree().get_multiplayer().get_remote_sender_id(), " send ", data)

@rpc("any_peer", "call_local", "reliable", 0)
func player_set_readiness(readiness):
	if Main.root_mp.is_server():
		Server.player_set_ready(Main.root_mp.get_remote_sender_id(), readiness)

@rpc("authority", "call_local", "reliable", 0)
func server_send(data: PackedByteArray):
	var gs = Proto.GameState.new()
	gs.from_bytes(data)
	print(gs)

@rpc("any_peer", "call_remote", "reliable", 0)
func client_hello(client_display_name):
	if Main.root_mp.is_server() == false:
		return
	var pid = str(Main.root_mp.get_remote_sender_id())
	EventBus.sent_feedback.emit(pid + " joined as " + client_display_name)
	Server.add_player(pid, client_display_name)

@rpc("authority", "call_local", "reliable", 0)
func update_player_list(data: PackedByteArray):
	EventBus.player_list_updated.emit(data)

func create_game_state():
	var gs = Proto.GameState.new()
	gs.set_turn(1)
	var g1: Proto.Grid = gs.new_gmap()
	g1.add_tags("RedSpawn")
	g1.add_tags("BlueSpawn")
	g1.set_x(100)
	g1.set_y(10)
	var g2 = g1.new_next()
	g2.set_x(-100)
	g2.set_y(10)
	print(gs)
	return gs

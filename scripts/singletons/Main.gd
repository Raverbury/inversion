extends Node

@onready var root_mp: MultiplayerAPI = get_tree().get_multiplayer()

enum AppState {DISCONNECTED, CONNECTED, IN_GAME, CONNECTING}
var app_state: AppState = AppState.DISCONNECTED

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var client_display_name
var client_is_ready = false

var game_node

func _ready():
	root_mp.connected_to_server.connect(on_connected_to_server)
	root_mp.connection_failed.connect(on_connection_failed)
	root_mp.server_disconnected.connect(on_disconnected_to_server)
	root_mp.peer_disconnected.connect(on_peer_disconnected)
	EventBus.pressed_server_host.connect(on_server_host_pressed)
	EventBus.pressed_server_join.connect(on_server_join_pressed)
	EventBus.pressed_disconnect.connect(on_disconnect_pressed)
	EventBus.pressed_ready.connect(on_ready_pressed)
	EventBus.pressed_start.connect(on_start_pressed)
	EventBus.game_is_ready.connect(on_game_is_ready)

func set_enable(node: Node, value: bool):
	node.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED

# Client calls this
func on_connected_to_server():
	app_state = AppState.CONNECTED
	EventBus.sent_feedback.emit("[color=green]Joined server[/color]")
	Rpc.client_hello.rpc_id(1, client_display_name)

# Client calls this
func on_disconnected_to_server():
	EventBus.sent_feedback.emit("[color=red]Disconnected from server[/color]")
	self.dc_cleanup()

# Client calls this
func on_connection_failed():
	EventBus.sent_feedback.emit("[color=red]Could not join server[/color]")
	self.dc_cleanup()

# Server calls this
func on_peer_disconnected(peer_id):
	if root_mp.is_server():
		var player_display_name = Server.remove_player(peer_id)
		EventBus.sent_feedback.emit("%s (%s) left the server" % [player_display_name, str(peer_id)])

# Server calls this
func on_server_host_pressed(display_name, port):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(int(port))
	if error:
		EventBus.sent_feedback.emit(error)
		return
	root_mp.multiplayer_peer = peer
	if root_mp.is_server() == false:
		EventBus.sent_feedback.emit("[color=red]Server could not start[/color]")
		return
	EventBus.sent_feedback.emit("[color=green]Server started on port " + port + "[/color]")
	app_state = AppState.CONNECTED
	Server.initialize()
	Server.add_player(1, display_name)

# Client calls this
func on_server_join_pressed(display_name, address: String):
	var comps: PackedStringArray = address.split(":")
	if len(comps) != 2:
		EventBus.sent_feedback.emit("[color=red]Bad server address[/color]")
		return
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(comps[0], int(comps[1]))
	if error:
		EventBus.sent_feedback.emit(error)
		return
	root_mp.multiplayer_peer = peer
	client_display_name = display_name
	EventBus.sent_feedback.emit("Attempting to connect to " + address + "...")
	app_state = AppState.CONNECTING

# Both call this
func on_disconnect_pressed():
	if root_mp.is_server():
		EventBus.sent_feedback.emit("[color=green]Server shutdown[/color]")
		Server.wipe()
	else:
		EventBus.sent_feedback.emit("[color=green]Left the server[/color]")
		EventBus.player_list_updated.emit(Proto.PlayerList.new().to_bytes())
	self.dc_cleanup()

# Common connection close cleanup
func dc_cleanup():
	root_mp.multiplayer_peer.close()
	root_mp.multiplayer_peer = null
	client_is_ready = false
	app_state = AppState.DISCONNECTED
	EventBus.player_list_updated.emit(Proto.PlayerList.new().to_bytes())
	if self.game_node:
		self.game_node.queue_free()
		self.game_node = null

# Both call this
func on_ready_pressed():
	client_is_ready = !client_is_ready
	Rpc.player_set_readiness.rpc_id(1, client_is_ready)

func on_start_pressed():
	if root_mp.is_server():
		Server.request_start_game()

func on_game_is_ready(map_path):
	var packed_game_scene = load("res://assets/scenes/game/game.tscn") as PackedScene
	self.game_node = packed_game_scene.instantiate()
	get_tree().root.add_child(game_node)
	get_tree().root.move_child(game_node, 0)
	game_node.load_map(map_path)
	self.app_state = AppState.IN_GAME
	EventBus.sent_feedback.emit("[color=green]Game started[/color]")

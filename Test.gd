extends Control

@onready var address_field: LineEdit = $LineEdit
@onready var join_tickbox: CheckBox = $CheckBox
@onready var root_mp: MultiplayerAPI = get_tree().get_multiplayer()
var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	root_mp.peer_connected.connect(_on_peer_connected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if Client.is_in_server:
			Global.player_ready.rpc_id(1)
		else:
			if join_tickbox.button_pressed:
				print("Client", address_field.text)
				peer.create_client(address_field.text)
				root_mp.multiplayer_peer = peer
			else:
				print("Server", address_field.text)
				peer.create_server(9001)
				root_mp.multiplayer_peer = peer
				Server.add_player(1)
			Client.is_in_server = true
	pass

func _on_peer_connected(id):
	print(id, " ", root_mp.get_unique_id(), " ", root_mp.is_server())
	if root_mp.is_server():
		Server.add_player(id)
		print(Server.players)
		Global.test.rpc_id(id, "Hello from server!")
	else:
		print("Hello?")
		Global.test.rpc("Hello from client!")

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
		if join_tickbox.button_pressed:
			print("Uh", address_field.text)
			peer.create_client(address_field.text)
			root_mp.multiplayer_peer = peer
		else:
			print("WTF", address_field.text)
			peer.create_server(9001)
			root_mp.multiplayer_peer = peer
	pass

func _on_peer_connected(id):
	print(id, " ", root_mp.get_unique_id(), " ", root_mp.is_server())
	if root_mp.get_unique_id() != 1:
		print("Hello?")
		Global.test.rpc("Hello world!")

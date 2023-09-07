extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@rpc("any_peer", "call_local", "reliable", 0)
func test(data):
	print(get_tree().get_multiplayer().get_remote_sender_id(), " send ", data)

@rpc("any_peer", "call_local", "reliable", 0)
func player_ready():
	if get_tree().get_multiplayer().is_server():
		Server.player_ready(get_tree().get_multiplayer().get_remote_sender_id())

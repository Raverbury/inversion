extends Node

var players: Dictionary = {}

func add_player(pid):
	players[pid] = Player.new(pid)

func player_ready(pid):
	players[pid].is_ready = true
	for k in players:
		if players[k].is_ready == false:
			return
	print("All ready")

class Player:
	var peer_id
	var is_ready
	func _init(pid):
		peer_id = pid
		is_ready = false

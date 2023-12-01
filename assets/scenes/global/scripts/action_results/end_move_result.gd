class_name EndMoveResult extends ActionResult

var player_id: int

# to allow empty ctor
func set_stuff(pid):
	player_id = pid
	return self


# override in base
func show():
	EventBus.player_sprite_ended_movement_chain.emit(player_id)
	finished.emit()


func _to_string():
	return "<EndMoveResult pid: %d>" % [player_id]

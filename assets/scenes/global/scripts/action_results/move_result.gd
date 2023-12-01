class_name MoveResult extends ActionResult

var player_id: int
var direction: int

# to allow empty ctor
func set_stuff(pid, _direction):
	player_id = pid
	direction = _direction
	return self


# override in base
func show():
	EventBus.player_sprite_move_finished.connect(__player_sprite_move_finished_handler)
	EventBus.player_sprite_moved.emit(player_id, direction)


func __player_sprite_move_finished_handler():
	EventBus.player_sprite_move_finished.disconnect(__player_sprite_move_finished_handler)
	finished.emit()


func _to_string():
	return "<MoveResult pid: %d direction: %d>" % [player_id, direction]
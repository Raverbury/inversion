class_name PopupFeedbackResult extends ActionResult

var player_id: int
var message: String
var color: Color
var is_dead: bool

# to allow empty ctor
func set_stuff(pid, _msg, _color, _dead):
	player_id = pid
	message = _msg
	color = _color
	is_dead = _dead
	return self


func set_stuff_for_take_damage(pid: int, damage: int, _dead):
	color = Color.RED
	player_id = pid
	message = "-%s" % str(damage)
	is_dead = _dead
	return self


func set_stuff_for_miss(pid: int):
	color = Color.BLACK
	player_id = pid
	message = "MISSED"
	is_dead = false
	return self


# override in base
func show():
	EventBus.player_sprite_popup_finished.connect(__popup_finished_handler)
	EventBus.player_sprite_popup_displayed.emit(player_id, message, color, is_dead)


func __popup_finished_handler():
	EventBus.player_sprite_popup_finished.disconnect(__popup_finished_handler)
	finished.emit()


func _to_string():
	return "<PopupFeedbackResult pid: %d msg: %s color: %s fatal: %s>" % [player_id, message, color, is_dead]

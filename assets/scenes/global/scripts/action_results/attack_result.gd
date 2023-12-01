class_name AttackResult extends ActionResult

var player_id: int
var target_mapgrid: Vector2i

# to allow empty ctor
func set_stuff(pid, _mapgrid):
	player_id = pid
	target_mapgrid = _mapgrid
	return self


# override in base
func show():
	EventBus.player_sprite_attack_finished.connect(__player_sprite_attack_finished_handler)
	EventBus.player_sprite_attacked.emit(player_id, target_mapgrid)


func __player_sprite_attack_finished_handler():
	EventBus.player_sprite_attack_finished.disconnect(__player_sprite_attack_finished_handler)
	finished.emit()


func _to_string():
	return "<AttackResult pid: %d target: %s>" % [player_id, target_mapgrid]

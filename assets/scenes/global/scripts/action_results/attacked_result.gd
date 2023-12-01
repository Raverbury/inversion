class_name AttackedResult extends ActionResult

var player_id: int
var is_a_hit: bool
var damage_taken: int
var is_dead: bool

# to allow empty ctor
func set_stuff(pid, _hit, _damage, _dead):
	player_id = pid
	is_a_hit = _hit
	damage_taken = _damage
	is_dead = _dead
	return self


# override in base
func show():
	EventBus.player_sprite_was_attacked.emit(player_id, is_a_hit, damage_taken, is_dead)
	finished.emit()


func _to_string():
	return "<AttackedResult pid: %d hit: %s damage: %d fatal: %s>" % [player_id, is_a_hit, damage_taken, is_dead]

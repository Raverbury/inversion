class_name GamePlayer extends AnimatedSprite2D

@export var sprite_name: String
var is_moving: bool = false
var last_dir: int = 0

func _ready():
	play("move")

func _process(delta):
	move_with_lerp_wrapper()

func move_with_lerp_wrapper():
	if is_moving:
		return
	last_dir = (last_dir + 4) if last_dir < 20 else (0 if last_dir % 4 == 2 else 2)
	move_with_lerp(last_dir % 4)

# 0 1 2 3 left up right down
func move_with_lerp(move_direction: int):
	if is_moving:
		return
	is_moving = true
	var target_pos = Vector2(global_position.x + (-32 if move_direction == 0 else (32 if move_direction == 2 else 0)), global_position.y + (-32 if move_direction == 3 else (32 if move_direction == 1 else 0)))
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", target_pos, 0.4)
	t.finished.connect(on_move_done)
	if move_direction == 0:
		flip_h = true
	elif move_direction == 2:
		flip_h = false

func on_move_done():
	is_moving = false

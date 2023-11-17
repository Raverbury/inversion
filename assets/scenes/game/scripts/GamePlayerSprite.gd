class_name GamePlayerSprite extends AnimatedSprite2D

var player_id: int = -1
var display_name: String

@export var sprite_name: String
var is_moving: bool = false
var last_dir: int = 0

@onready var display_name_label = $DisplayName

var queued_movement: Array = []

func _ready():
	play("idle")
	display_name_label.text = display_name
	EventBus.player_moved.connect(__player_moved_handler)


# func _process(_delta):
	# __process_queued_movement()


func __process_queued_movement():
	if queued_movement.is_empty():
		play("idle")
		return
	if is_moving:
		return
	last_dir = queued_movement.pop_front()
	play("move")
	__move_with_lerp(last_dir)


func __move_with_lerp(move_direction: int):
	is_moving = true
	var target_pos = Vector2(global_position.x + (-32 if move_direction == 0 else (32 if move_direction == 2 else 0)), global_position.y + (-32 if move_direction == 3 else (32 if move_direction == 1 else 0)))
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", target_pos, 0.4)
	t.finished.connect(__on_move_done)
	if move_direction == 0:
		flip_h = true
	elif move_direction == 2:
		flip_h = false

func __on_move_done():
	is_moving = false
	__process_queued_movement()


func set_mapgrid_pos(mapgrid_position: Vector2):
	global_position = mapgrid_position * 32 + Vector2(16, 16)


func __player_moved_handler(pid: int, steps: Array):
	if player_id != pid:
		return
	if is_moving == true:
		return
	queued_movement.append_array(steps)
	__process_queued_movement()

class_name GameCamera extends Camera2D

var max_camera_zoom: Vector2 = Vector2(4.0, 4.0)
var min_camera_zoom: Vector2 = Vector2(0.8, 0.8)
var max_x: float = 800
var max_y: float = 500
var pan_sensitivity: float = 10.0

var is_in_tween: bool = false

func _init():
	zoom = Vector2(2, 2)


func _ready():
	EventBus.camera_force_panned.connect(__camera_force_panned_handler)
	EventBus.camera_panned.connect(__camera_panned_handler)
	EventBus.camera_zoomed.connect(__camera_zoomed_handler)


func __camera_force_panned_handler(pos: Vector2, duration: float):
	var tween = create_tween()
	is_in_tween = true
	tween.tween_property(self, "global_position", pos, duration)
	tween.finished.connect(__force_panned_tween_finished)


func __force_panned_tween_finished():
	is_in_tween = false


func __camera_panned_handler(pan_direction: Vector2):
	if is_in_tween == true:
		return
	var to_be_x = clampf(position.x + pan_direction.x * pan_sensitivity/zoom.x, -max_x, max_x)
	var to_be_y = clampf(position.y + pan_direction.y * pan_sensitivity/zoom.y, -max_y, max_y)
	global_position = Vector2(to_be_x, to_be_y)


func __camera_zoomed_handler(zoom_direction: int):
	var to_be_zoom = zoom + (zoom_direction * Vector2(0.08, 0.08) * zoom)
	zoom = clamp(to_be_zoom, min_camera_zoom, max_camera_zoom)

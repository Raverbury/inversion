extends PanningCamera

func _init():
	zoom_sensititvity = 1.5
	zoom = Vector2(2, 2)

func pan_camera_to(pos: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos, 1.5)

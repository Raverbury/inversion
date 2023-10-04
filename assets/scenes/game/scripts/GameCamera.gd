extends Camera2D

func _input(event):
	if event is InputEventMouseButton:
		var zoom_level = zoom.x
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level - 0.05, 0.3)
			zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level + 0.05, 2.5)
			zoom = Vector2(zoom_level, zoom_level)

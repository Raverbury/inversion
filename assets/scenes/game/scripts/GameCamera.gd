extends PanningCamera

func _init():
	zoom_sensititvity = 1.5
	zoom = Vector2(2, 2)


func _ready():
	EventBus.camera_panned.connect(_camera_panned_handler)


func _camera_panned_handler(pos: Vector2, duration: float):
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos, duration)

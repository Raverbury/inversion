class_name GameClassPanel extends Panel

@export var game_class_id: int
var is_locked_in: bool = false
var is_selected: bool = false
var is_mouse_over: bool = false

func _ready():
	custom_minimum_size = Vector2(230, 0)
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	gui_input.connect(on_gui_input)
	EventBus.game_class_selected.connect(on_game_class_selected)

func on_mouse_entered():
	if is_locked_in == true:
		return
	is_mouse_over = true
	auto_set_color()

func on_mouse_exited():
	if is_locked_in == true:
		return
	is_mouse_over = false
	auto_set_color()

func on_gui_input(event: InputEvent):
	if is_locked_in == true:
		return
	if is_mouse_over:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				EventBus.game_class_selected.emit(game_class_id)

func on_game_class_selected(gcid):
	if is_locked_in == true:
		return
	if game_class_id == gcid:
		is_selected = true
	else:
		is_selected = false
	auto_set_color()

func auto_set_color():
	if is_mouse_over && is_selected:
		modulate = Color.GREEN
	elif is_mouse_over:
		modulate = Color.TEAL
	elif is_selected:
		modulate = Color.LAWN_GREEN
	else:
		modulate = Color.WHITE

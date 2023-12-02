class_name EndTurnPromptUI extends Panel

@onready var label: Label = $Label
@onready var do_not_remind_check_box: CheckBox = $DoNotRemindAgain
@onready var yes_button: Button = $Yes
@onready var no_button: Button = $No

var is_shown: bool = false
var hide_offset = Vector2(0, 1000)

var NO_AP_TEXT = "Do you wish to end your turn?"
var HAS_AP_TEXT = "%s There are still AP left." % NO_AP_TEXT

func _ready():
	EventBus.end_turn_prompt_ui_freed.connect(queue_free)
	EventBus.end_turn_prompt_showed.connect(__end_turn_prompt_showed_handler)
	yes_button.pressed.connect(__yes_button_pressed)
	no_button.pressed.connect(__no_button_pressed)
	set_display(false)


func _input(event):
	if is_shown == false:
		return
	if event.is_action_released("y_key"):
		__yes_button_pressed()
	elif event.is_action_released("n_key"):
		__no_button_pressed()


func set_display(value: bool = true):
	is_shown = value
	EventBus.anim_is_being_played.emit(value)

	position += hide_offset * (-1 if value == true else 1)


func __end_turn_prompt_showed_handler(has_remaining_ap: bool):
	label.self_modulate = Color.RED if has_remaining_ap == true else Color.WHITE
	label.text = HAS_AP_TEXT if has_remaining_ap == true else NO_AP_TEXT
	set_display(true)


func __yes_button_pressed():
	set_display(false)
	EventBus.end_turn_confirmed.emit(do_not_remind_check_box.button_pressed)


func __no_button_pressed():
	set_display(false)
	EventBus.end_turn_canceled.emit()

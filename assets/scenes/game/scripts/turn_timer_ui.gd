class_name TurnTimerUI extends Panel

@onready var timer: Label = $Timer

var tween_timer: Tween

func _ready():
	EventBus.turn_timer_ui_freed.connect(__freed_handler)
	EventBus.turn_timer_refreshed.connect(__turn_timer_refreshed_handler)


func __turn_timer_refreshed_handler():
	if tween_timer != null:
		tween_timer.kill()
		tween_timer = null
	tween_timer = create_tween()
	tween_timer.tween_method(__set_timer_text, Global.Constant.Misc.TURN_TIMER_DURATION, 0,
		Global.Constant.Misc.TURN_TIMER_DURATION)


func __set_timer_text(duration_left):
	timer.text = str(duration_left)
	if duration_left <= 10:
		if duration_left & 1:
			timer.label_settings.font_color = Color.RED
		else:
			timer.label_settings.font_color = Color.WHITE
	else:
		timer.label_settings.font_color = Color.WHITE


func __freed_handler():
	if tween_timer != null:
		tween_timer.kill()
		tween_timer = null
	queue_free()

class_name CustomTooltipControl extends Control

func _make_custom_tooltip(for_text):
	var label = Label.new()
	# label.text = "WTF"
	# return label
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	label.text = for_text
	label.custom_minimum_size = Vector2((get_viewport_rect()).size.x * 0.6, (get_viewport_rect()).size.y * 0.6)
	return label
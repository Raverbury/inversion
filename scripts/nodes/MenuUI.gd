extends Control

@onready var tab_container: TabContainer = $"TabContainer"
@onready var host_line_edit: LineEdit = $"TabContainer/Host/LineEdit"
@onready var host_button: Button = $"TabContainer/Host/Button"

@onready var join_line_edit: LineEdit = $"TabContainer/Join/LineEdit"
@onready var join_button: Button = $"TabContainer/Join/Button"

@onready var name_line_edit: LineEdit = $"NameContainer/Control/LineEdit"

@onready var feedback_container: TabContainer = $"FeedbackContainer"
@onready var feedback_rich_text_label: RichTextLabel = $"FeedbackContainer/Control/RichTextLabel"
@onready var disconnect_button: Button = $"FeedbackContainer/Control/Button"

@onready var player_list: VBoxContainer = $"PlayerList/Control/ScrollContainer/VBoxContainer"

@onready var hide_button: Button = $"HideButton"
@onready var show_button: Button = $"ShowButton"

@onready var ready_button: Button = $"ReadyButton"
@onready var start_button: Button = $"StartButton"

@onready var ready_check_box: CheckBox = $"ReadyCheckBox"

const DEFAULT_NAMES = ["StinkyPineapple", "McCheese", "LeetKid420", "DisplayName", "AndyPhm", "IUseArchBTW"]

var is_shown = true

func _ready():
	host_button.pressed.connect(on_host_button_pressed)
	join_button.pressed.connect(on_join_button_pressed)
	disconnect_button.pressed.connect(on_disconnect_button_pressed)
	hide_button.pressed.connect(on_hide_button_pressed)
	show_button.pressed.connect(on_show_button_pressed)
	ready_button.pressed.connect(on_ready_button_pressed)
	start_button.pressed.connect(on_start_button_pressed)

	EventBus.sent_feedback.connect(on_feedback_sent)
	EventBus.player_list_updated.connect(on_player_list_updated)

func _process(_delta):
	if Main.app_state == Main.AppState.DISCONNECTED:
		Main.set_enable(tab_container, true)
		disconnect_button.disabled = true
		host_button.disabled = false
		join_button.disabled = false
		ready_button.disabled = true
		start_button.disabled = true
	elif Main.app_state == Main.AppState.CONNECTING:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = true
		host_button.disabled = true
		join_button.disabled = true
		ready_button.disabled = true
		start_button.disabled = true
	elif Main.app_state == Main.AppState.CONNECTED:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = false
		host_button.disabled = true
		join_button.disabled = true
		ready_button.disabled = false
		if Server.is_initialized == true && Server.room_is_ready == true:
			start_button.disabled = false
		else:
			start_button.disabled = true
	elif Main.app_state == Main.AppState.IN_GAME:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = false
		host_button.disabled = true
		join_button.disabled = true
		ready_button.disabled = true
		start_button.disabled = true
	ready_check_box.button_pressed = Main.client_is_ready

func get_display_name():
	if name_line_edit.text == "":
		name_line_edit.text = DEFAULT_NAMES[randi_range(0, len(DEFAULT_NAMES) - 1)]
	return name_line_edit.text

func on_host_button_pressed():
	EventBus.pressed_server_host.emit(get_display_name(), host_line_edit.text)

func on_join_button_pressed():
	EventBus.pressed_server_join.emit(get_display_name(), join_line_edit.text)

func on_disconnect_button_pressed():
	EventBus.pressed_disconnect.emit()

func on_feedback_sent(message):
	feedback_rich_text_label.append_text(str(message) + "\n")
	# feedback_rich_text_label.scroll_vertical = feedback_rich_text_label.get_v_scroll_bar().max_value

func on_hide_button_pressed():
	set_display(false)

func on_show_button_pressed():
	set_display(true)

func on_ready_button_pressed():
	EventBus.pressed_ready.emit()

func on_start_button_pressed():
	EventBus.pressed_start.emit()

func set_display(value = true):
	is_shown = value
	var t = create_tween()
	t.tween_property(self, "position", Vector2(0 if value else -1280, 0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	# position.x = 0 if value else -1280

func on_player_list_updated(data: PackedByteArray):
	var pl = Proto.PlayerList.new()
	pl.from_bytes(data)
	for n in player_list.get_children():
		player_list.remove_child(n)
		n.queue_free()
	var pl_dict = pl.get_player_list()
	print(pl_dict)
	for k in pl_dict:
		var control = Control.new()
		control.custom_minimum_size = Vector2(player_list.size.x, 40.0)
		var role_label = get_new_label_for_player_list(0.0, 0.15)
		var id_label = get_new_label_for_player_list(0.15, 0.45)
		var name_label = get_new_label_for_player_list(0.45, 0.85)
		var ready_label = get_new_label_for_player_list(0.85, 1.0)
		role_label.set_text("Host" if k == "1" else "")
		id_label.set_text(k)
		id_label.set_tooltip_text(k)
		name_label.set_text(pl_dict[k].get_display_name())
		name_label.set_tooltip_text(pl_dict[k].get_display_name())
		ready_label.set_text("Ready" if pl_dict[k].get_is_ready() else "")
		if k == str(Main.root_mp.get_unique_id()):
			role_label.label_settings.font_color = Color.YELLOW
			id_label.label_settings.font_color = Color.YELLOW
			name_label.label_settings.font_color = Color.YELLOW
			ready_label.label_settings.font_color = Color.YELLOW
		control.add_child(role_label)
		control.add_child(id_label)
		control.add_child(name_label)
		control.add_child(ready_label)
		player_list.add_child(control)

func get_new_label_for_player_list(left_anchor = 0.0, right_anchor = 0.0):
	var label: Label = Label.new()
	label.label_settings = LabelSettings.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.anchor_left = left_anchor
	label.anchor_top = 0.0
	label.anchor_right = right_anchor
	label.anchor_bottom = 1.0
	label.offset_left = 0
	label.offset_top = 0
	label.offset_right = 0
	label.offset_left = 0
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	return label

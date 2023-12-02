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

@onready var chat_line_edit: LineEdit = $"FeedbackContainer/Control/LineEdit"

const DEFAULT_NAMES = ["StinkyPineapple", "McCheese", "LeetKid420", "DisplayName", "AndyPhm", "IUseArchBTW",
	"FMJ7.62x51", "1v1 me rust", "AYAYA AYAYA", "OBAMA YOSHI", "original name", "howdoiwriteincap", "MemeLord420",
	"general_generous", "admiral_admirable", "captain_captive", "private_prying", "target package romeo", "CritRollPlz",
	"ImagineLizard", "DivineTsundere", "malding maldino", "mad teacher", "#1 NALCS Coach", "lame weasel", "NerfElectroPea",
	"WdymISkipLunch", "MittensOnKittens", "dm me 4 free vbucks", "come@me.bro", "TerribleDay", "xX_qu1cksc0p3r_Xx",
	"\"name' OR 'a'='a\"", "\"a'); DELETE FROM items; --\"", "CritDmgRollPlz", "IAbstractFactoryBuilder"
]

var is_shown = true
var unread_chat_message = 0

func _ready():
	host_button.pressed.connect(on_host_button_pressed)
	join_button.pressed.connect(on_join_button_pressed)
	disconnect_button.pressed.connect(on_disconnect_button_pressed)
	hide_button.pressed.connect(on_hide_button_pressed)
	show_button.pressed.connect(on_show_button_pressed)
	ready_button.pressed.connect(on_ready_button_pressed)
	start_button.pressed.connect(on_start_button_pressed)

	EventBus.sent_feedback.connect(on_feedback_sent)
	EventBus.server_sent_chat_message.connect(__server_sent_chat_message_handler)
	EventBus.player_list_updated.connect(on_player_list_updated)
	EventBus.game_is_ready.connect(on_game_is_ready)

	chat_line_edit.text_submitted.connect(__client_sent_chat_message_handler)

func _process(_delta):
	if Main.app_state == Main.AppState.DISCONNECTED:
		Main.set_enable(tab_container, true)
		disconnect_button.disabled = true
		host_button.disabled = false
		join_button.disabled = false
		ready_button.disabled = true
		start_button.disabled = true
		Main.set_enable(chat_line_edit, false)
		Main.set_enable(name_line_edit, true)
	elif Main.app_state == Main.AppState.CONNECTING:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = false
		host_button.disabled = true
		join_button.disabled = true
		ready_button.disabled = true
		start_button.disabled = true
		Main.set_enable(chat_line_edit, false)
		Main.set_enable(name_line_edit, false)
	elif Main.app_state == Main.AppState.CONNECTED:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = false
		host_button.disabled = true
		join_button.disabled = true
		ready_button.disabled = false
		Main.set_enable(chat_line_edit, true)
		Main.set_enable(name_line_edit, false)
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
		Main.set_enable(chat_line_edit, true)
		Main.set_enable(name_line_edit, false)
	ready_check_box.button_pressed = Main.client_is_ready


func _input(event):
	if event.is_action_released("ui_cancel"):
		set_display(not is_shown)


func get_display_name():
	if name_line_edit.text == "":
		name_line_edit.text = Global.Util.get_random_from_list(DEFAULT_NAMES)
	return name_line_edit.text

func on_host_button_pressed():
	EventBus.pressed_server_host.emit(get_display_name(), host_line_edit.text)

func on_join_button_pressed():
	EventBus.pressed_server_join.emit(get_display_name(), join_line_edit.text)

func on_disconnect_button_pressed():
	EventBus.pressed_disconnect.emit()

func on_feedback_sent(message):
	feedback_rich_text_label.append_text(str(message) + "\n")
	feedback_rich_text_label.scroll_to_line(feedback_rich_text_label.get_line_count())

func on_hide_button_pressed():
	set_display(false)

func on_show_button_pressed():
	set_display(true)

func on_ready_button_pressed():
	EventBus.pressed_ready.emit()

func on_start_button_pressed():
	EventBus.pressed_start.emit()

func set_display(value = true):
	# Control.print_orphan_nodes()
	if is_shown == value:
		return
	is_shown = value
	if value == true:
		show_button.text = "Show"
		unread_chat_message = 0
	if value == false:
		hide()
		show()
	EventBus.game_input_enabled.emit(is_shown)
	var t = create_tween()
	t.tween_property(self, "position", Vector2(0 if value else -1280, 0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	# position.x = 0 if value else -1280

func on_player_list_updated(pl_dict: Dictionary):
	for n in player_list.get_children():
		player_list.remove_child(n)
		n.queue_free()
	for pid in pl_dict:
		var control = Control.new()
		control.custom_minimum_size = Vector2(player_list.size.x, 40.0)
		var role_label = get_new_label_for_player_list(0.0, 0.15)
		var id_label = get_new_label_for_player_list(0.15, 0.45)
		var name_label = get_new_label_for_player_list(0.45, 0.85)
		var ready_label = get_new_label_for_player_list(0.85, 1.0)
		role_label.set_text("Host" if pid == 1 else "")
		id_label.set_text(str(pid))
		id_label.set_tooltip_text(str(pid))
		name_label.set_text(pl_dict[pid].display_name)
		name_label.set_tooltip_text(pl_dict[pid].display_name)
		ready_label.set_text("Ready" if pl_dict[pid].is_ready else "")
		if pid == Main.root_mp.get_unique_id():
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

func on_game_is_ready(_map_name):
	set_display(false)


func __client_sent_chat_message_handler(text):
	EventBus.client_sent_chat_message.emit(text)
	chat_line_edit.clear()


func __server_sent_chat_message_handler(text, color):
	feedback_rich_text_label.push_color(color)
	feedback_rich_text_label.append_text(str(text) + "\n")
	feedback_rich_text_label.pop()
	feedback_rich_text_label.scroll_to_line(feedback_rich_text_label.get_line_count())
	if is_shown == false:
		unread_chat_message += 1
		show_button.text = "Show\n(%d)" % unread_chat_message

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

const DEFAULT_NAMES = ["StinkyPineapple", "McCheese", "LeetKid420", "DisplayName", "AndyPham", "IUseArchBTW"]

var is_shown = true

func _ready():
	host_button.pressed.connect(on_host_button_pressed)
	join_button.pressed.connect(on_join_button_pressed)
	disconnect_button.pressed.connect(on_disconnect_button_pressed)
	EventBus.sent_feedback.connect(on_feedback_sent)
	hide_button.pressed.connect(on_hide_button_pressed)
	show_button.pressed.connect(on_show_button_pressed)
	EventBus.player_list_updated.connect(on_player_list_updated)

func _process(_delta):
	if Main.app_state == Main.AppState.DISCONNECTED:
		Main.set_enable(tab_container, true)
		disconnect_button.disabled = true
		host_button.disabled = false
		join_button.disabled = false
	elif Main.app_state == Main.AppState.CONNECTING:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = true
		host_button.disabled = true
		join_button.disabled = true
	elif Main.app_state == Main.AppState.CONNECTED:
		Main.set_enable(tab_container, false)
		disconnect_button.disabled = false
		host_button.disabled = true
		join_button.disabled = true

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

func set_display(value = true):
	is_shown = value
	position.x = 0 if value else -1280

func on_player_list_updated(data: PackedByteArray):
	var pl = Proto.PlayerList.new()
	pl.from_bytes(data)
	for n in player_list.get_children():
		player_list.remove_child(n)
		n.queue_free()
	var pl_dict = pl.get_player_list()
	print(pl_dict)
	for k in pl_dict:
		var label = Label.new()
		label.text = pl_dict[k].get_display_name()
		player_list.add_child(label)

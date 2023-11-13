extends Panel

var last_gc_id: int = -1
@onready var confirm_button = $ConfirmButton
@onready var hbox_container = $HBoxContainer

func _ready():
	create_class_panels()
	EventBus.game_class_selected.connect(on_game_class_selected)
	confirm_button.pressed.connect(on_confirm_button_pressed)

func create_class_panels():
	var classes = Global.PlayerClassData.CLASS_DATA
	for class_id in classes:
		var class_data = Global.PlayerClassData.CLASS_DATA[class_id]
		var csp = GameClassPanel.new()
		csp.game_class_id = class_id
		var label = Label.new()
		label.text = "%s\n%s" % [class_data[0], class_data[10]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		csp.add_child(label)
		hbox_container.add_child(csp)

func on_game_class_selected(gcid):
	last_gc_id = gcid

func on_confirm_button_pressed():
	confirm_button.text = "STANDBY..."
	confirm_button.disabled = true
	for child in hbox_container.get_children():
		child.is_locked_in = true
	Rpc.player_pick_class.rpc_id(1, SRLZ.serialize(PlayerPickClassMessage.new(last_gc_id)))

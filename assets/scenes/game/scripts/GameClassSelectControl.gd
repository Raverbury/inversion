extends Panel

var last_gc_id: int = -1
@onready var confirm_button = $ConfirmButton

func _ready():
	EventBus.game_class_selected.connect(on_game_class_selected)
	confirm_button.pressed.connect(on_confirm_button_pressed)

func on_game_class_selected(gcid):
	last_gc_id = gcid

func on_confirm_button_pressed():
	var a = Wuta.new()
	a.data = 2
	Rpc.player_pick_class.rpc_id(1, last_gc_id, var_to_str(a))

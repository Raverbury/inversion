extends Panel

var last_gc_id: int = -1
@onready var confirm_button = $ConfirmButton

func _ready():
	EventBus.game_class_selected.connect(on_game_class_selected)
	confirm_button.pressed.connect(on_confirm_button_pressed)

func on_game_class_selected(gcid):
	last_gc_id = gcid

func on_confirm_button_pressed():
	Rpc.player_pick_class.rpc_id(1, SRLZ.serialize(PlayerPickClassMessage.new(last_gc_id)))

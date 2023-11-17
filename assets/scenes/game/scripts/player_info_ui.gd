class_name PlayerInfoUI extends Panel

@onready var display_name_label: Label = $DisplayName
@onready var pid_label: Label = $PlayerID
@onready var hp_label: Label = $HP
@onready var accuracy_label: Label = $Accuracy
@onready var evasion_label: Label = $Evasion
@onready var armor_label: Label = $Armor
@onready var ap_label: Label = $AP
@onready var attack_power_label: Label = $AttackPower
@onready var attack_range_label: Label = $AttackRange
@onready var attack_cost_label: Label = $AttackCost
@onready var vision_range_label: Label = $VisionRange

var cached_player: Player

func _ready():
	EventBus.player_info_updated.connect(__player_info_updated_handler)
	EventBus.ap_cost_updated.connect(__ap_cost_updated_handler)
	EventBus.player_info_ui_freed.connect(queue_free)


func __player_info_updated_handler(player: Player, stat_mods: Dictionary):
	cached_player = player
	var player_game_data = player.player_game_data
	display_name_label.text = "%s %s" % [player_game_data.cls_name, player.display_name]
	pid_label.text = "PID: %s" % player.peer_id
	hp_label.text = "HP: %s/%s" % [player_game_data.current_hp, player_game_data.max_hp]
	accuracy_label.text = "Accuracy: %s (%s)" % [player_game_data.accuracy,
		("+%s" % stat_mods["accuracy_mod"] if stat_mods["accuracy_mod"] >= 0 else stat_mods["accuracy_mod"])
			if stat_mods.has("accuracy_mod") else "+0"]
	evasion_label.text = "Evasion: %s (%s)" % [player_game_data.evasion,
		("+%s" % stat_mods["evasion_mod"] if stat_mods["evasion_mod"] >= 0 else stat_mods["evasion_mod"])
			if stat_mods.has("evasion_mod") else "+0"]
	armor_label.text = "Armor: %s (%s)" % [player_game_data.armor,
		("+%s" % stat_mods["armor_mod"] if stat_mods["armor_mod"] >= 0 else stat_mods["armor_mod"])
			if stat_mods.has("armor_mod") else "+0"]
	ap_label.text = "AP: %s (-0)/%s" % [player_game_data.current_ap, player_game_data.max_ap]
	attack_power_label.text = "Attack power: %s" % [player_game_data.attack_power]
	attack_range_label.text = "Attack range: %s" % [player_game_data.attack_range]
	attack_cost_label.text = "Attack cost: %s" % [player_game_data.attack_cost]
	# vision_range_label.text = "Vision range: %s" % [player_game_data.vision_range]
	vision_range_label.text = "Vision range: -----"


func __ap_cost_updated_handler(ap_cost):
	var player_game_data = cached_player.player_game_data
	ap_label.text = "AP: %s %s/%s" % [player_game_data.current_ap, "(-%s)" % ap_cost, player_game_data.max_ap]

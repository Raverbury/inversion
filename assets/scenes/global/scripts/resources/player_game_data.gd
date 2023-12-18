class_name PlayerGameData extends RefCounted

var mapgrid_position: Vector2i = Vector2i.ZERO
var class_id: int = 0
var cls_name: String = 'PLACEHOLDER_CLASS'
var current_hp: int = 10
var max_hp: int = 10
var accuracy: int = 10
var evasion: int = 0
var armor: int = 0
var attack_power: int = 5
var attack_range: int = 10
var attack_cost: int = 2
var max_ap: int = 10
var current_ap: int = 10
var vision_range: int = 10
var ranged_accuracy_modifier: Array = []
var weapon_name: String = "Weapon"
var doll_name: String = "id152"
var effect_descriptions: String = ""

func _to_string():
	return "%s, %d/%d at %s" % [cls_name, current_hp, max_hp, mapgrid_position]


func get_card_description():
	return ("HP: %s\nAP: %s\nACC: %s\nEVA: %s\nArmor: %s\nAttack power: %s\nAttack range: %s\nAttack cost: %s\nVision range: %s\nWeapon: %s" %
		[max_hp, max_ap, accuracy, evasion, armor, attack_power, attack_range, attack_cost, vision_range, weapon_name])
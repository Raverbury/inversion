class_name PlayerGameData extends Object

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

func _to_string():
	return "%s, %d/%d at %s" % [cls_name, current_hp, max_hp, mapgrid_position]
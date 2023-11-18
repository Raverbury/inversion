class_name PlayerAttackRequestMessage extends Message

var target_mapgrid: Vector2i

func _init(_target_mapgrid = Vector2i.ZERO):
	target_mapgrid = _target_mapgrid
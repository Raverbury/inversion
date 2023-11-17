class_name PlayerMoveRequestMessage extends Message

var move_steps: Array = []

func _init(_move_steps: Array = []):
	move_steps = _move_steps
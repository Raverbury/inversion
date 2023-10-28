class_name PlayerSetReadinessMessage extends Message

var readiness: bool = false

func _init(_readiness = false):
	readiness = _readiness
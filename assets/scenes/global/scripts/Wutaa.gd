class_name Wuta extends Resource

var data: int
var v2: Vector2 = Vector2(1,1)
var st: String = "No"

func _to_string():
  return "%s %s %s" % [data, v2, st]
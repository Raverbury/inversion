class_name Message extends RefCounted

var sender_pid: int = 0

func _init():
	sender_pid = Main.root_mp.get_unique_id()
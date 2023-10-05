extends Node

var rng_source = RandomNumberGenerator.new()

func _ready():
	rng_source.seed = int(Time.get_unix_time_from_system())

func get_random_from_list(list):
	var length = len(list)
	return list[rng_source.randi_range(0, length - 1)]

class Set:
	var dic: Dictionary = {}

	func clear():
		self.dic = {}
	
	func has(item):
		return dic.has(item)
	
	func add(item):
		if self.has(item):
			return
		self.dic[item] = 1
	
	func pop(item):
		if self.has(item):
			self.dic.erase(item)
		return
	
	func items():
		return self.dic.keys()
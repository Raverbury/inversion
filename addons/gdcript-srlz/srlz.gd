# Author: github.com/raverbury

class_name SRLZ

# These can be whatever, as long as
# they don't conflict with other script paths
const ID_ARRAY_TYPE: String = "special://array"
const ID_DICTIONARY_TYPE: String = "special://dictionary"

# Example dict structure
# var example = {
# 	"type": "res://path/to/class.gd",
# 	"data": {
# 		"some_int": {
# 			"type": "",
# 			"data": 2
# 		},
# 		"obj": {
# 			"type": "res://another/path/to/class.gd",
# 			"data": {
# 				"hp": {
# 					"type": "",
# 					"data": 10
# 				}
# 			}
# 		},
# 		"arr": {
# 			"type": "special://array",
# 			"data": [
# 				{
# 					"type": "",
# 					"data": 1
# 				},
# 				{
# 					"type": "",
# 					"data": 2
# 				}
# 			]
# 		},
# 		"dict": {
# 			"type": "special://dictionary",
# 			"data": {
# 				2: {
# 					"type": "",
# 					"data": 2
# 				},
# 			}
# 		}
# 	}
# }


static func deserialize(dict: Dictionary):
	var obj_type_string: String = dict["type"]
	var obj

	if obj_type_string == ID_ARRAY_TYPE:
		obj = []
		var list = dict["data"]
		for item in list:
			obj.append(deserialize(item))

	elif obj_type_string == ID_DICTIONARY_TYPE:
		obj = {}
		var data = dict["data"]
		# Assuming using primitives for keys
		for key in data.keys():
			var value = data[key]
			obj[key] = deserialize(value)

	elif obj_type_string == "":
		obj = dict["data"]

	else:
		obj = load(obj_type_string).new()
		var data = dict["data"]
		for prop_name in data.keys():
			var prop_data = data[prop_name]
			obj.set(prop_name, deserialize(prop_data))

	return obj


static func serialize(obj) -> Dictionary:
	var obj_type: int = typeof(obj)
	var object_type_string: String = ""
	var data

	if obj_type == TYPE_OBJECT:
		# Returns an empty string for classes declared
		# with the class keyword so they don't work
		object_type_string = obj.get_script().get_path()
		data = {}
		for property in obj.get_property_list():
			if property["usage"] == PROPERTY_USAGE_SCRIPT_VARIABLE:
				var sobj = obj.get(property["name"])
				data[property["name"]] = serialize(sobj)

	elif obj_type == TYPE_ARRAY:
		object_type_string = ID_ARRAY_TYPE
		data = []
		for item in obj:
			data.append(serialize(item))

	elif obj_type == TYPE_DICTIONARY:
		object_type_string = ID_DICTIONARY_TYPE
		data = {}
		# Assuming using primitives for keys
		for key in obj:
			data[key] = serialize(obj[key])

	else:
		object_type_string = ""
		data = obj

	return {"type": object_type_string, "data": data}

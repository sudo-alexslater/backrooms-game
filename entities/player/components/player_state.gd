extends Resource
class_name PlayerState

@export
var name := ""
@export 
var id := 1


func _init(dict: Dictionary = {}):
	if !dict.is_empty():
		from_dict(dict)

func to_dict():
	return {
		"name": name,
		"id": id
	}
func from_dict(dict: Dictionary):
	name = dict["name"]
	id = dict["id"]
func _to_string():
	return str(to_dict())

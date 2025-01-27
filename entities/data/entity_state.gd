extends Resource
class_name EntityState

@export var guid: String
@export var initial_position := Vector3(0, 0, 0)
@export var node: PackedScene
@export var options: Dictionary

func _init(from_dict = {}) -> void:
	if from_dict.has("guid"):
		guid = from_dict["guid"]
	if from_dict.has("initial_position"):
		initial_position = from_dict["initial_position"]
	if from_dict.has("node_path"):
		node = load(from_dict["node_path"])
	if from_dict.has("options"):
		options = from_dict["options"]

func to_dict() -> Dictionary:
	return {
		"guid": guid,
		"initial_position": initial_position,
		"node_path": node.resource_path,
		"options": options
	}

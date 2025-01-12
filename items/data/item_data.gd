extends Resource
class_name ItemData

@export var quantity: int = 0
@export var stackable: bool = true
@export var max_stack: int = 64
@export var formatted_name: String = ""
@export var icon: Texture2D
@export var item_id: String = ""
@export var guid: String = ""

func _init(from_dict: Dictionary = {}):
	if !from_dict.is_empty():
		formatted_name = from_dict.formatted_name
		icon = load(from_dict.icon_path)
		item_id = from_dict.item_id
		guid = from_dict.guid
		quantity = from_dict.quantity
		stackable = from_dict.stackable
		max_stack = from_dict.max_stack
	else: 
		icon = load("res://items/resources/empty.png")	
		
func to_dict():
	return {
		"formatted_name": formatted_name,
		"icon_path": icon.resource_path,
		"item_id": item_id,
		"guid": guid,
		"quantity": quantity,
		"stackable": stackable,
		"max_stack": max_stack
	}

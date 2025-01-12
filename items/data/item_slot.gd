extends Resource
class_name ItemSlot

@export
var item_guid: String = ""
@export
var item: ItemData :
	get: 
		var registered_item = ItemService.get_item(item_guid)
		if !registered_item:
			# return empty item
			return ItemData.new()
		return registered_item
@export
var row: int = 0
@export
var col: int = 0
var empty : bool : 
	get:
		return !item_guid or item.guid == ""

func _init(from_dict: Dictionary = {}):
	if !from_dict.is_empty():
		row = from_dict.row
		col = from_dict.col
		item_guid = from_dict.item_guid

func to_dict():
	return {
		"row": row,
		"col": col,
		"item_guid": item_guid
	}

extends Node

var all_item_datas: Dictionary = {
	"bones": {
		"quantity": 0,
		"stackable": true,
		"max_stack": 64,
		"formatted_name": "Bones",
		"icon_path": "res://items/resources/bones.png",
		"item_id": "bones",
		"guid": ""
	},
	"medal": {
		"quantity": 0,
		"stackable": true,
		"max_stack": 16,
		"formatted_name": "Medal",
		"icon_path": "res://items/resources/medal.png",
		"item_id": "medal",
		"guid": ""
	}
}
var items: Dictionary = {}
func get_items_serialised() -> Dictionary:
	var serialised_items = {}
	for item in items:
		serialised_items[item.guid] = item.to_dict()
	return serialised_items
func get_item(guid: String) -> ItemData:
	if items.has(guid):
		return items[guid]
	else:
		return null
@rpc("any_peer")
func put_item(guid: String, item: ItemData):
	items[guid] = item
	update_item_list.rpc(get_items_serialised())
@rpc("any_peer")
func remove_item(guid: String):
	items.erase(guid)
	update_item_list.rpc(get_items_serialised())
@rpc("any_peer")
func new_random_item() -> String:
	var random_item = all_item_datas.values().pick_random()
	var random_quantity = randi_range(1, random_item.max_stack)
	random_item.quantity = random_quantity
	random_item.guid = IDService.v4()
	items[random_item.guid] = ItemData.new(random_item)
	return random_item.guid
@rpc("authority")
func update_item_list(new_items: Dictionary):
	items.clear()
	for item_dict in new_items:
		items[item_dict.guid] = ItemData.new(item_dict)

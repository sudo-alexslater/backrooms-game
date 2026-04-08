extends Node
const IDServiceScript = preload("res://services/id_service.gd")

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
var items: Dictionary = {
}
func get_items_serialised() -> Dictionary:
	var serialised_items = {}
	for item_key in items:
		var item = items[item_key]
		serialised_items[item.guid] = item.to_dict()
	return serialised_items
func get_item(guid: String) -> ItemData:
	if items.has(guid):
		return items[guid]
	else:
		return null
@rpc("any_peer")
func put_item(guid: String, item: ItemData):
	if not NetworkService.is_authority():
		return
	items[guid] = item
	update_item_list.rpc(get_items_serialised())
@rpc("any_peer")
func remove_item(guid: String):
	if not NetworkService.is_authority():
		return
	items.erase(guid)
	update_item_list.rpc(get_items_serialised())
@rpc("any_peer")
func new_random_item() -> String:
	if not NetworkService.is_authority():
		return ""
	var random_item_template = all_item_datas.values().pick_random()
	var random_item = random_item_template.duplicate(true)
	var random_quantity = randi_range(1, int(random_item.max_stack))
	random_item.quantity = random_quantity
	random_item.guid = IDServiceScript.v4()
	items[random_item.guid] = ItemData.new(random_item)
	update_item_list.rpc(get_items_serialised())
	return random_item.guid
@rpc("authority")
func update_item_list(new_items: Dictionary):
	items.clear()
	for item_key in new_items:
		var item_dict = new_items[item_key]
		items[item_dict.guid] = ItemData.new(item_dict)
@rpc("any_peer")
func fetch_network_items():
	if not NetworkService.is_authority():
		return
	update_item_list.rpc(get_items_serialised())

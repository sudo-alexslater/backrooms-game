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
var items: Dictionary = {}


func _sync_items() -> void:
	update_item_list.rpc(get_items_serialised())


func get_items_serialised() -> Dictionary:
	var serialised_items := {}
	for item_key in items:
		var item = items[item_key]
		serialised_items[item.guid] = item.to_dict()
	return serialised_items


func get_item(guid: String) -> ItemData:
	if items.has(guid):
		return items[guid]
	return null


@rpc("any_peer")
func put_item(guid: String, item: ItemData) -> void:
	if not NetworkService.is_authority():
		return
	items[guid] = item
	_sync_items()


@rpc("any_peer")
func remove_item(guid: String) -> void:
	if not NetworkService.is_authority():
		return
	items.erase(guid)
	_sync_items()


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
	_sync_items()
	return random_item.guid


## Merge from source stack into destination stack (authority). Removes source item if depleted.
func merge_into(dest_guid: String, source_guid: String) -> Dictionary:
	if not NetworkService.is_authority():
		return {"from_depleted": false, "merged": 0}
	if dest_guid == source_guid:
		return {"from_depleted": false, "merged": 0}
	var dest = get_item(dest_guid)
	var src = get_item(source_guid)
	if dest == null or src == null:
		return {"from_depleted": false, "merged": 0}
	if dest.item_id != src.item_id or not dest.stackable or not src.stackable:
		return {"from_depleted": false, "merged": 0}
	var space: int = dest.max_stack - dest.quantity
	var mv: int = mini(space, src.quantity)
	if mv <= 0:
		return {"from_depleted": false, "merged": 0}
	src.quantity -= mv
	dest.quantity += mv
	var from_depleted: bool = src.quantity <= 0
	if from_depleted:
		items.erase(source_guid)
	_sync_items()
	return {"from_depleted": from_depleted, "merged": mv}


## Split take_qty units off source into a new item instance. Returns new guid or "" on failure.
func split_off_quantity(source_guid: String, take_qty: int) -> String:
	if not NetworkService.is_authority():
		return ""
	var src = get_item(source_guid)
	if src == null or take_qty <= 0 or take_qty >= src.quantity:
		return ""
	var d: Dictionary = src.to_dict()
	d.guid = IDServiceScript.v4()
	d.quantity = take_qty
	src.quantity -= take_qty
	items[d.guid] = ItemData.new(d)
	_sync_items()
	return str(d.guid)


@rpc("authority")
func update_item_list(new_items: Dictionary) -> void:
	items.clear()
	for item_key in new_items:
		var item_dict = new_items[item_key]
		items[item_dict.guid] = ItemData.new(item_dict)


@rpc("any_peer")
func fetch_network_items() -> void:
	if not NetworkService.is_authority():
		return
	update_item_list.rpc(get_items_serialised())

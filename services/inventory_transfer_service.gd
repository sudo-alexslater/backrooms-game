extends Node

func resolve_inventory_from_owner(inventory_owner: Node) -> EntityInventory:
	if inventory_owner == null:
		return null
	if inventory_owner.has_method("get_inventory"):
		var inventory = inventory_owner.get_inventory()
		if inventory is EntityInventory:
			return inventory
	return null

func resolve_inventory_path_from_owner(inventory_owner: Node) -> NodePath:
	var inventory = resolve_inventory_from_owner(inventory_owner)
	if inventory == null:
		return NodePath("")
	return inventory.get_path()

@rpc("any_peer", "call_remote")
func request_transfer(from_inventory_path: NodePath, to_inventory_path: NodePath, item_guid: String) -> bool:
	if not NetworkService.is_authority():
		return false
	return _apply_transfer(from_inventory_path, to_inventory_path, item_guid)

func request_transfer_local(from_inventory_path: NodePath, to_inventory_path: NodePath, item_guid: String) -> bool:
	if NetworkService.is_authority():
		return _apply_transfer(from_inventory_path, to_inventory_path, item_guid)
	request_transfer.rpc_id(1, from_inventory_path, to_inventory_path, item_guid)
	return true

func _apply_transfer(from_inventory_path: NodePath, to_inventory_path: NodePath, item_guid: String) -> bool:
	var from_inventory := get_node_or_null(from_inventory_path)
	var to_inventory := get_node_or_null(to_inventory_path)
	if not (from_inventory is EntityInventory):
		GameLogger.error("Transfer failed: source inventory not found " + str(from_inventory_path))
		return false
	if not (to_inventory is EntityInventory):
		GameLogger.error("Transfer failed: destination inventory not found " + str(to_inventory_path))
		return false

	var slot = from_inventory.get_slot_by_guid(item_guid)
	if slot.is_empty():
		return false
	if not to_inventory.has_free_slot():
		return false

	to_inventory.add_slot(slot)
	from_inventory.remove_slot_with_id(item_guid)
	return true

@rpc("any_peer", "call_remote")
func request_seed_random_item(target_inventory_path: NodePath) -> bool:
	if not NetworkService.is_authority():
		return false
	return _seed_random_item(target_inventory_path)

func request_seed_random_item_local(target_inventory_path: NodePath) -> bool:
	if NetworkService.is_authority():
		return _seed_random_item(target_inventory_path)
	request_seed_random_item.rpc_id(1, target_inventory_path)
	return true

func _seed_random_item(target_inventory_path: NodePath) -> bool:
	var target_inventory := get_node_or_null(target_inventory_path)
	if not (target_inventory is EntityInventory):
		GameLogger.error("Seed failed: target inventory not found " + str(target_inventory_path))
		return false
	var guid = ItemService.new_random_item()
	if guid == "":
		return false
	target_inventory.add_slot({"row": 0, "col": 0, "item_guid": guid})
	return true


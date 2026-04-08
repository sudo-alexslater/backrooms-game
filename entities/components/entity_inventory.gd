extends Node
class_name EntityInventory

signal updated
const InventoryOpsScript = preload("res://services/inventory_ops.gd")

@export
var columns: int :
	set(input):
		columns = input
		resize_inventory()
	get:
		return columns
@export
var rows: int :
	set(input):
		rows = input
		resize_inventory()
	get:
		return rows
@export
var slots: Array[Dictionary] = []
var size: int : 
	get: 
		return rows * columns

func _ready():
	if not NetworkService.is_authority():
		fetch_from_network.rpc_id(1)

@rpc("authority", "call_local")
func update_network(new_slots: Array[Dictionary]):
	slots = InventoryOpsScript.sanitize_slots(new_slots)
	updated.emit()
@rpc("any_peer", "call_remote")
func fetch_from_network():
	if not NetworkService.is_authority():
		return
	update_network.rpc(slots)
func update_slots(new_slots: Array[Dictionary]): 
	var normalized_slots = InventoryOpsScript.sanitize_slots(new_slots)
	if not NetworkService.is_authority():
		return
	# init()/setters can run before this node is inside the tree.
	# In that phase, rpc() is invalid; keep local state and sync later through normal entity updates.
	if not is_inside_tree():
		slots = normalized_slots
		return
	update_network.rpc(normalized_slots)

func resize_inventory():
	if not NetworkService.is_authority():
		return
	update_slots(InventoryOpsScript.resize_slots(slots, rows, columns))

func add_slot(slot: Dictionary) -> void:
	if not NetworkService.is_authority():
		return
	update_slots(InventoryOpsScript.add_slot(slots, slot, rows, columns))

func remove_slot_with_id(guid: String) -> void:
	if not NetworkService.is_authority():
		return
	update_slots(InventoryOpsScript.remove_slot_with_id(slots, guid))

func clear_inventory() -> void:
	if not NetworkService.is_authority():
		return
	update_slots([])

func has_free_slot() -> bool:
	return not InventoryOpsScript.find_free_slot(slots, rows, columns).is_empty()

func get_slot_by_guid(guid: String) -> Dictionary:
	for slot in slots:
		if str(slot.get("item_guid", "")) == guid:
			return slot
	return {}

func get_item(row: int, col: int) -> Dictionary:
	return InventoryOpsScript.get_item(slots, row, col)

func init(input_dict: Dictionary = {}):
	if input_dict.has("columns"): columns = int(input_dict["columns"])
	if input_dict.has("rows"): rows = int(input_dict["rows"])
	if input_dict.has("slots"): slots = InventoryOpsScript.sanitize_slots(input_dict["slots"])
func to_dict():
	return {
		"columns": columns,
		"rows": rows,
		"slots": InventoryOpsScript.sanitize_slots(slots)
	}

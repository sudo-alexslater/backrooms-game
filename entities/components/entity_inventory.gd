extends Node
class_name EntityInventory

signal updated

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


func _ready() -> void:
	if not NetworkService.is_authority():
		fetch_from_network.rpc_id(1)


@rpc("authority", "call_local")
func update_network(new_slots: Array[Dictionary]) -> void:
	slots = InventoryOps.sanitize_slots(new_slots)
	updated.emit()


## Slot layout unchanged (e.g. after ItemService merge_into). Replicates `updated` so UIs refresh counts from ItemService.
@rpc("authority", "call_local")
func notify_display_refresh() -> void:
	# Defer so `ItemService.update_item_list` RPC is applied first on peers.
	call_deferred("_emit_updated_deferred")


func _emit_updated_deferred() -> void:
	updated.emit()


@rpc("any_peer", "call_remote")
func fetch_from_network() -> void:
	if not NetworkService.is_authority():
		return
	update_network.rpc(slots)


func update_slots(new_slots: Array[Dictionary]) -> void:
	var normalized_slots := InventoryOps.sanitize_slots(new_slots)
	if not NetworkService.is_authority():
		return
	if not is_inside_tree():
		slots = normalized_slots
		return
	update_network.rpc(normalized_slots)


func resize_inventory() -> void:
	if not NetworkService.is_authority():
		return
	update_slots(InventoryOps.resize_slots(slots, rows, columns))


func clear_inventory() -> void:
	if not NetworkService.is_authority():
		return
	update_slots([])


func authority_place_item_first_free(item_guid: String) -> bool:
	if not NetworkService.is_authority():
		return false
	var res := InventoryOps.add_item_first_free(slots, item_guid, rows, columns)
	if not res.ok:
		return false
	update_slots(res.slots)
	return true


func get_slot_at_coords(row: int, col: int) -> Dictionary:
	return InventoryOps.get_slot_at(slots, row, col)


func init(input_dict: Dictionary = {}) -> void:
	if input_dict.has("columns"):
		columns = int(input_dict["columns"])
	if input_dict.has("rows"):
		rows = int(input_dict["rows"])
	if input_dict.has("slots"):
		slots = InventoryOps.sanitize_slots(input_dict["slots"])


func to_dict() -> Dictionary:
	return {
		"columns": columns,
		"rows": rows,
		"slots": InventoryOps.sanitize_slots(slots)
	}

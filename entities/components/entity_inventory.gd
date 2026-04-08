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

func _ready():
	if not NetworkService.is_authority():
		fetch_from_network.rpc_id(1)

@rpc("any_peer", "call_local")
func update_network(new_slots: Array[Dictionary]):
	slots = new_slots
	updated.emit()
@rpc("any_peer", "call_remote")
func fetch_from_network():
	if not NetworkService.is_authority():
		return
	update_network.rpc(slots)
func update_slots(new_slots: Array[Dictionary]): 
	update_network.rpc(new_slots)
	updated.emit()
func resize_inventory():
	var all_slots = slots.duplicate(true)
	# reinsert items, tracking items that don't fit since resize
	var items_needing_new_slots: Array[Dictionary] = []
	for slot in all_slots:
		var row_num = slot.row
		var col_num = slot.col 
		var row_doesnt_fit = slot.row > rows - 1
		var col_doesnt_fit = slot.col > columns - 1
		var existing_item_in_slot = get_item(row_num, col_num)
		if row_doesnt_fit or col_doesnt_fit or (existing_item_in_slot != null and existing_item_in_slot.item_guid != slot.item_guid):
			items_needing_new_slots.push_back(slot)
			continue
	# reassign slots that didn't fit due to resize
	for slot_to_reassign in items_needing_new_slots:
		var slot_found = false
		for row_num in range(rows):
			for col_num in range(columns):
				if get_item(row_num, col_num) == null:
					slot_found = true
					slot_to_reassign.row = row_num
					slot_to_reassign.col = col_num
					break
			if slot_found:
				break
		if not slot_found:
			print("[!] Orphaned item from inventory resize: ", slot_to_reassign.item.guid)
	update_slots(all_slots)
func add_slot(slot: Dictionary) -> void:
	var all_slots = slots.duplicate(true)
	# find first free slot
	for row_index in range(rows):
		for column_index in range(columns):
			if get_item(row_index, column_index).is_empty():
				# set slot col and row and exit
				slot.col = column_index
				slot.row = row_index
				all_slots.push_back(slot)
				update_slots(all_slots)
				return
func remove_slot_with_id(guid: String) -> void:
	var all_slots = slots.duplicate(true)
	# find and remove from master slot list
	for slot in all_slots:
		if slot.item_guid == guid:
			all_slots.erase(slot)
			break
	update_slots(all_slots)
func clear_inventory() -> void:
	update_slots([])
func get_item(row: int, col: int) -> Dictionary:
	for slot in slots:
		if slot.row == row and slot.col == col:
			return slot
	return {}

func init(input_dict: Dictionary = {}):
	if input_dict.has("columns"):
		columns = input_dict["columns"]
	if input_dict.has("rows"):
		rows = input_dict["rows"]
	if input_dict.has("slots"):
		slots = input_dict["slots"]
func to_dict():
	return {
		"columns": columns,
		"rows": rows,
		"slots": slots
	}

extends Resource
class_name InventoryData

signal inventory_updated()

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
var slots: Array[ItemSlot] :
	set(input):
		slots = input
		resize_inventory()
	get: 
		return slots
var size: int : 
	get: 
		return rows * columns

func _init(input_dict: Dictionary = {}):
	if !input_dict.is_empty():
		columns = input_dict.columns
		rows = input_dict.rows
		var new_slots: Array[ItemSlot] = []
		for slot_data in input_dict.slots:
			new_slots.push_back(ItemSlot.new(slot_data))
		slots = new_slots

func resize_inventory():
	# reinsert items, tracking items that don't fit since resize
	var items_needing_new_slots: Array[ItemSlot] = []
	for slot in slots:
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
	inventory_updated.emit()
	
func add_slot(slot: ItemSlot) -> void:
	# find first free slot
	for row_index in range(rows):
		for column_index in range(columns):
			if get_item(row_index, column_index) == null:
				# set slot col and row and exit
				slot.col = column_index
				slot.row = row_index
				slots.push_back(slot)
				inventory_updated.emit()
				return

func remove_slot_with_id(guid: String) -> void:
	# find and remove from master slot list
	for slot in slots:
		if slot.item and slot.item.guid == guid:
			slots.erase(slot)
	inventory_updated.emit()
	
func clear_inventory() -> void:
	slots = []
	
func get_item(row: int, col: int) -> ItemSlot:
	for slot in slots:
		if slot.row == row and slot.col == col:
			return slot
	return null

func to_dict():
	return {
		"columns": columns,
		"rows": rows,
		"slots": slots.map(func(slot): return slot.to_dict())
	}

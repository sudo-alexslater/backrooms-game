extends RefCounted
class_name InventoryOps

static func sanitize_slot(slot: Dictionary) -> Dictionary:
	if not slot.has("item_guid") or str(slot.item_guid) == "":
		return {}
	return {
		"row": int(slot.get("row", 0)),
		"col": int(slot.get("col", 0)),
		"item_guid": str(slot.item_guid)
	}

static func sanitize_slots(input_slots: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in input_slots:
		var normalized = sanitize_slot(slot)
		if normalized.is_empty():
			continue
		out.push_back(normalized)
	return out

static func get_item(slots: Array[Dictionary], row: int, col: int) -> Dictionary:
	for slot in slots:
		if int(slot.get("row", -1)) == row and int(slot.get("col", -1)) == col:
			return slot
	return {}

static func find_free_slot(slots: Array[Dictionary], rows: int, columns: int) -> Dictionary:
	for row_index in range(rows):
		for column_index in range(columns):
			if get_item(slots, row_index, column_index).is_empty():
				return {
					"row": row_index,
					"col": column_index
				}
	return {}

static func resize_slots(input_slots: Array[Dictionary], rows: int, columns: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in sanitize_slots(input_slots):
		if int(slot.row) < rows and int(slot.col) < columns and get_item(out, int(slot.row), int(slot.col)).is_empty():
			out.push_back(slot)
			continue

		var target = find_free_slot(out, rows, columns)
		if target.is_empty():
			GameLogger.error("Orphaned item from inventory resize: " + str(slot.item_guid))
			continue
		slot.row = target.row
		slot.col = target.col
		out.push_back(slot)
	return out

static func add_slot(input_slots: Array[Dictionary], slot: Dictionary, rows: int, columns: int) -> Array[Dictionary]:
	var out = sanitize_slots(input_slots)
	var normalized = sanitize_slot(slot)
	if normalized.is_empty():
		return out
	if has_item_guid(out, str(normalized.item_guid)):
		return out
	var target = find_free_slot(out, rows, columns)
	if target.is_empty():
		return out
	normalized.row = target.row
	normalized.col = target.col
	out.push_back(normalized)
	return out

static func remove_slot_with_id(input_slots: Array[Dictionary], guid: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in sanitize_slots(input_slots):
		if str(slot.item_guid) == guid:
			continue
		out.push_back(slot)
	return out

static func has_item_guid(slots: Array[Dictionary], guid: String) -> bool:
	for slot in slots:
		if str(slot.get("item_guid", "")) == guid:
			return true
	return false


extends RefCounted
class_name InventoryOps

## Pure grid helpers: sparse slots as { row, col, item_guid }

static func op_result(ok: bool, reason: String = "", slots: Array[Dictionary] = []) -> Dictionary:
	return {"ok": ok, "reason": reason, "slots": slots}


static func sanitize_slot(slot: Dictionary) -> Dictionary:
	if slot == null:
		return {}
	if not slot.has("item_guid") or str(slot.item_guid) == "":
		return {}
	return {
		"row": int(slot.get("row", 0)),
		"col": int(slot.get("col", 0)),
		"item_guid": str(slot.item_guid)
	}


static func sanitize_slots(input_slots: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen_cells := {}
	var seen_guids := {}
	for raw in input_slots:
		var s = sanitize_slot(raw)
		if s.is_empty():
			continue
		var ck := "%d,%d" % [int(s.row), int(s.col)]
		var g := str(s.item_guid)
		if seen_cells.has(ck) or seen_guids.has(g):
			continue
		seen_cells[ck] = true
		seen_guids[g] = true
		out.append(s)
	return out


static func clone_slots(slots: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in slots:
		out.append({
			"row": int(s.row),
			"col": int(s.col),
			"item_guid": str(s.item_guid)
		})
	return out


static func is_in_bounds(row: int, col: int, rows: int, columns: int) -> bool:
	return row >= 0 and col >= 0 and row < rows and col < columns


static func get_slot_at(slots: Array, row: int, col: int) -> Dictionary:
	for s in slots:
		if int(s.row) == row and int(s.col) == col:
			return s
	return {}


static func find_slot_index_at(slots: Array, row: int, col: int) -> int:
	for i in range(slots.size()):
		var s = slots[i]
		if int(s.row) == row and int(s.col) == col:
			return i
	return -1


static func find_free_cell(slots: Array, rows: int, columns: int) -> Dictionary:
	for row_index in range(rows):
		for column_index in range(columns):
			if get_slot_at(slots, row_index, column_index).is_empty():
				return {"row": row_index, "col": column_index}
	return {}


static func has_item_guid(slots: Array, guid: String) -> bool:
	for s in slots:
		if str(s.get("item_guid", "")) == guid:
			return true
	return false


static func remove_slot_at(slots: Array, row: int, col: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in slots:
		if int(s.row) == row and int(s.col) == col:
			continue
		out.append(s.duplicate() if s is Dictionary else s)
	return out


static func resize_slots(input_slots: Array, rows: int, columns: int) -> Array[Dictionary]:
	var cleaned := sanitize_slots(input_slots)
	var out: Array[Dictionary] = []
	for slot in cleaned:
		var r := int(slot.row)
		var c := int(slot.col)
		if is_in_bounds(r, c, rows, columns) and get_slot_at(out, r, c).is_empty():
			out.append(slot.duplicate())
			continue
		var target := find_free_cell(out, rows, columns)
		if target.is_empty():
			GameLogger.error("Orphaned item from inventory resize: " + str(slot.item_guid))
			continue
		var ns := slot.duplicate()
		ns.row = target.row
		ns.col = target.col
		out.append(ns)
	return out


static func add_item_first_free(slots: Array, item_guid: String, rows: int, columns: int) -> Dictionary:
	var g := str(item_guid)
	if g.is_empty():
		return op_result(false, "bad_guid", clone_slots(slots))
	var base := sanitize_slots(slots)
	if has_item_guid(base, g):
		return op_result(false, "duplicate_guid", base)
	var cell := find_free_cell(base, rows, columns)
	if cell.is_empty():
		return op_result(false, "inventory_full", base)
	var ns := clone_slots(base)
	ns.append({"row": cell.row, "col": cell.col, "item_guid": g})
	return op_result(true, "", ns)


static func move_slot_to_empty(slots: Array, fr: int, fc: int, to_row: int, to_col: int, rows: int, columns: int) -> Dictionary:
	if not is_in_bounds(fr, fc, rows, columns) or not is_in_bounds(to_row, to_col, rows, columns):
		return op_result(false, "out_of_bounds", sanitize_slots(slots))
	if fr == to_row and fc == to_col:
		return op_result(false, "noop", sanitize_slots(slots))
	var src := get_slot_at(slots, fr, fc)
	if src.is_empty():
		return op_result(false, "no_source", sanitize_slots(slots))
	if not get_slot_at(slots, to_row, to_col).is_empty():
		return op_result(false, "dest_occupied", sanitize_slots(slots))
	var ns := clone_slots(slots)
	var ix := find_slot_index_at(ns, fr, fc)
	if ix < 0:
		return op_result(false, "missing_source", sanitize_slots(slots))
	ns[ix].row = to_row
	ns[ix].col = to_col
	return op_result(true, "", ns)


static func swap_slots_same_inventory(slots: Array, ar: int, ac: int, br: int, bc: int, rows: int, columns: int) -> Dictionary:
	if not is_in_bounds(ar, ac, rows, columns) or not is_in_bounds(br, bc, rows, columns):
		return op_result(false, "out_of_bounds", sanitize_slots(slots))
	var ia := find_slot_index_at(slots, ar, ac)
	var ib := find_slot_index_at(slots, br, bc)
	if ia < 0 or ib < 0:
		return op_result(false, "missing_slot", sanitize_slots(slots))
	var ns := clone_slots(slots)
	var tmp: String = str(ns[ia].item_guid)
	ns[ia].item_guid = str(ns[ib].item_guid)
	ns[ib].item_guid = tmp
	return op_result(true, "", ns)


## Cross-inventory: return new slot arrays for [from_slots, to_slots] after moving guid from (fr,fc) to empty (tr,tc)
static func cross_move_to_empty(from_slots: Array, fr: int, fc: int, to_slots: Array, to_row: int, to_col: int, item_guid: String, from_rows: int, from_cols: int, to_rows: int, to_cols: int) -> Dictionary:
	var g := str(item_guid)
	if not is_in_bounds(fr, fc, from_rows, from_cols) or not is_in_bounds(to_row, to_col, to_rows, to_cols):
		return {"ok": false, "reason": "out_of_bounds", "from_slots": sanitize_slots(from_slots), "to_slots": sanitize_slots(to_slots)}
	var src := get_slot_at(from_slots, fr, fc)
	if src.is_empty() or str(src.item_guid) != g:
		return {"ok": false, "reason": "source_mismatch", "from_slots": sanitize_slots(from_slots), "to_slots": sanitize_slots(to_slots)}
	if not get_slot_at(to_slots, to_row, to_col).is_empty():
		return {"ok": false, "reason": "dest_occupied", "from_slots": sanitize_slots(from_slots), "to_slots": sanitize_slots(to_slots)}
	if has_item_guid(to_slots, g):
		return {"ok": false, "reason": "guid_in_dest", "from_slots": sanitize_slots(from_slots), "to_slots": sanitize_slots(to_slots)}
	var ns_from := clone_slots(sanitize_slots(from_slots))
	var ns_to := clone_slots(sanitize_slots(to_slots))
	ns_from = remove_slot_at(ns_from, fr, fc)
	ns_to.append({"row": to_row, "col": to_col, "item_guid": g})
	return {"ok": true, "reason": "", "from_slots": ns_from, "to_slots": ns_to}


static func cross_swap(from_slots: Array, fr: int, fc: int, to_slots: Array, to_row: int, to_col: int, from_rows: int, from_cols: int, to_rows: int, to_cols: int) -> Dictionary:
	if not is_in_bounds(fr, fc, from_rows, from_cols) or not is_in_bounds(to_row, to_col, to_rows, to_cols):
		return {"ok": false, "reason": "out_of_bounds", "from_slots": sanitize_slots(from_slots), "to_slots": sanitize_slots(to_slots)}
	var a := get_slot_at(from_slots, fr, fc)
	var b := get_slot_at(to_slots, to_row, to_col)
	if a.is_empty() or b.is_empty():
		return {"ok": false, "reason": "swap_requires_two_items", "from_slots": sanitize_slots(from_slots), "to_slots": sanitize_slots(to_slots)}
	var ga := str(a.item_guid)
	var gb := str(b.item_guid)
	var ns_from := clone_slots(sanitize_slots(from_slots))
	var ns_to := clone_slots(sanitize_slots(to_slots))
	ns_from = remove_slot_at(ns_from, fr, fc)
	ns_to = remove_slot_at(ns_to, to_row, to_col)
	ns_from.append({"row": fr, "col": fc, "item_guid": gb})
	ns_to.append({"row": to_row, "col": to_col, "item_guid": ga})
	return {"ok": true, "reason": "", "from_slots": ns_from, "to_slots": ns_to}


static func remove_slot_with_guid(slots: Array, guid: String) -> Array[Dictionary]:
	var g := str(guid)
	var out: Array[Dictionary] = []
	for s in sanitize_slots(slots):
		if str(s.item_guid) == g:
			continue
		out.append(s)
	return out


## Legacy helper used by grids / debug
static func get_item(slots: Array, row: int, col: int) -> Dictionary:
	return get_slot_at(slots, row, col)

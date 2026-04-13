extends Node

## Server-authoritative inventory intents. NodePath addressing; UI uses two-click + shift/quick stack + right split.

const _DragPreviewScene = preload("res://components/inventory_drag_preview.tscn")

var _active_pick: Dictionary = {}
var _last_external_inventory_path: NodePath = NodePath("")
## When set, the local player has a world `ItemInventoryComponent` UI open (backpack uses half-screen layout).
var active_local_container_ui: Node = null
var _drag_preview: Node


func register_local_container_ui(component: Node) -> void:
	active_local_container_ui = component


func unregister_local_container_ui(component: Node) -> void:
	if active_local_container_ui == component:
		active_local_container_ui = null


func _ready() -> void:
	_drag_preview = _DragPreviewScene.instantiate()
	add_child(_drag_preview)


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


func notify_external_inventory_opened(inv: EntityInventory) -> void:
	if inv != null:
		_last_external_inventory_path = inv.get_path()


func notify_external_inventory_closed(inv: EntityInventory) -> void:
	if inv != null and inv.get_path() == _last_external_inventory_path:
		_last_external_inventory_path = NodePath("")


func _is_local_player_inventory(inv: EntityInventory) -> bool:
	var lp: Node = PlayerService.get_player_node_or_null(multiplayer.get_unique_id())
	if lp == null:
		return false
	if not lp.has_method("get_inventory"):
		return false
	return lp.get_inventory() == inv


func _inventory_owner_peer_id(inv: EntityInventory) -> int:
	var holder: Node = inv.get_parent()
	if holder == null:
		return -1
	var owner_node: Node = holder.get_parent()
	if owner_node is Player:
		return int(str(owner_node.name))
	return -1


func handle_ui_slot_input(inv: EntityInventory, slot: Dictionary, button_index: int, shift_pressed: bool, _ctrl_pressed: bool, context: Node) -> void:
	if inv == null:
		return
	var path := inv.get_path()

	if button_index == MOUSE_BUTTON_RIGHT:
		if slot.has("item_guid") and str(slot.item_guid) != "":
			request_slot_operation_local({
				"type": "split",
				"path": path,
				"row": int(slot.get("row", 0)),
				"col": int(slot.get("col", 0)),
				"guid": str(slot.item_guid)
			})
		_clear_pick()
		return

	if shift_pressed and slot.has("item_guid") and str(slot.item_guid) != "":
		_request_quick_transfer(path, slot, context)
		_clear_pick()
		return

	if button_index != MOUSE_BUTTON_LEFT:
		return

	if not slot.has("item_guid") or str(slot.item_guid) == "":
		# empty target
		if not _active_pick.is_empty():
			request_slot_operation_local({
				"type": "move_pair",
				"from_path": _active_pick.path,
				"fr": int(_active_pick.row),
				"fc": int(_active_pick.col),
				"from_guid": str(_active_pick.guid),
				"to_path": path,
				"tr": int(slot.get("row", 0)),
				"tc": int(slot.get("col", 0))
			})
		_clear_pick()
		return

	# clicked occupied cell
	if _active_pick.is_empty():
		_active_pick = {
			"path": path,
			"row": int(slot.row),
			"col": int(slot.col),
			"guid": str(slot.item_guid)
		}
		if _drag_preview != null and _drag_preview.has_method("show_for_item_guid"):
			_drag_preview.show_for_item_guid(str(slot.item_guid))
		return

	if path == NodePath(_active_pick.path) and int(slot.row) == int(_active_pick.row) and int(slot.col) == int(_active_pick.col):
		_clear_pick()
		return

	request_slot_operation_local({
		"type": "move_pair",
		"from_path": _active_pick.path,
		"fr": int(_active_pick.row),
		"fc": int(_active_pick.col),
		"from_guid": str(_active_pick.guid),
		"to_path": path,
		"tr": int(slot.row),
		"tc": int(slot.col)
	})
	_clear_pick()


func clear_active_pick() -> void:
	_clear_pick()


func _clear_pick() -> void:
	_active_pick = {}
	if _drag_preview != null and _drag_preview.has_method("hide_preview"):
		_drag_preview.hide_preview()


func _request_quick_transfer(from_path: NodePath, slot: Dictionary, context: Node) -> void:
	var fr := int(slot.row)
	var fc := int(slot.col)
	var guid := str(slot.item_guid)
	var to_inv: EntityInventory = null
	var from_inv := get_node_or_null(from_path)
	if from_inv is EntityInventory and _is_local_player_inventory(from_inv):
		if _last_external_inventory_path.is_empty():
			return
		to_inv = get_node_or_null(_last_external_inventory_path) as EntityInventory
	else:
		var player_node: Node = null
		if context is ItemInventoryComponent:
			player_node = context.interacting_entity
		if player_node != null and player_node.has_method("get_inventory"):
			to_inv = player_node.get_inventory() as EntityInventory
	if to_inv == null:
		return
	request_slot_operation_local({
		"type": "quick_stack",
		"from_path": from_path,
		"fr": fr,
		"fc": fc,
		"guid": guid,
		"to_path": to_inv.get_path()
	})


@rpc("any_peer", "call_remote")
func request_slot_operation(op: Dictionary) -> void:
	if not NetworkService.is_authority():
		return
	_apply_slot_operation(op)


func request_slot_operation_local(op: Dictionary) -> void:
	if NetworkService.is_authority():
		_apply_slot_operation(op)
	else:
		request_slot_operation.rpc_id(1, op)


@rpc("any_peer", "call_remote")
func request_seed_random_item(target_inventory_path: NodePath) -> void:
	if not NetworkService.is_authority():
		return
	_apply_slot_operation({"type": "seed_random", "path": target_inventory_path})


func request_seed_random_item_local(target_inventory_path: NodePath) -> void:
	if NetworkService.is_authority():
		_apply_slot_operation({"type": "seed_random", "path": target_inventory_path})
	else:
		request_seed_random_item.rpc_id(1, target_inventory_path)


func request_consume_item_local(inv: EntityInventory, slot: Dictionary) -> void:
	if inv == null:
		return
	if not slot.has("item_guid") or str(slot.item_guid) == "":
		return
	request_slot_operation_local({
		"type": "consume_item",
		"path": inv.get_path(),
		"row": int(slot.get("row", 0)),
		"col": int(slot.get("col", 0)),
		"guid": str(slot.item_guid)
	})


func _apply_slot_operation(op: Dictionary) -> void:
	if not NetworkService.is_authority():
		return
	var requesting_peer_id := multiplayer.get_remote_sender_id()
	if requesting_peer_id == 0:
		requesting_peer_id = multiplayer.get_unique_id()
	var t := str(op.get("type", ""))
	match t:
		"move_pair":
			_apply_move_pair(op)
		"split":
			_apply_split(op)
		"quick_stack":
			_apply_quick_stack(op)
		"seed_random":
			_apply_seed_random(op)
		"consume_item":
			_apply_consume_item(op, requesting_peer_id)
		_:
			GameLogger.error("Unknown inventory op: " + t)


func _apply_seed_random(op: Dictionary) -> void:
	var path: NodePath = op.get("path", NodePath(""))
	var inv := get_node_or_null(path)
	if not (inv is EntityInventory):
		GameLogger.error("Seed failed: invalid inventory path " + str(path))
		return
	var guid := ItemService.new_random_item()
	if guid == "":
		return
	inv.authority_place_item_first_free(guid)


func _apply_consume_item(op: Dictionary, requesting_peer_id: int) -> void:
	var path: NodePath = op.get("path", NodePath(""))
	var row := int(op.get("row", 0))
	var col := int(op.get("col", 0))
	var guid := str(op.get("guid", ""))
	var inv := get_node_or_null(path)
	if not (inv is EntityInventory):
		return
	if not _is_local_player_inventory_for_peer(inv, requesting_peer_id):
		return
	if _inventory_owner_peer_id(inv) != requesting_peer_id:
		return
	if not _validate_slot_occupant(inv, row, col, guid):
		return
	var item := ItemService.get_item(guid)
	if item == null:
		return
	var thirst_restore: Variant = ItemService.CONSUMABLE_THIRST_RESTORE.get(item.item_id, null)
	if thirst_restore == null:
		return

	#  consume one, or bail
	if not ItemService.consume_one_from_stack(guid):
		return

	#  update quantity or remove if depleted
	if ItemService.get_item(guid) == null:
		var ns := InventoryOps.remove_slot_with_guid(inv.slots, guid)
		inv.update_slots(ns)
	else:
		inv.notify_display_refresh.rpc()

	var amount := int(thirst_restore)
	var player_node: Node = PlayerService.get_player_node_or_null(requesting_peer_id)
	if player_node != null and player_node.has_method("apply_inventory_drink"):
		# rpc_id to yourself errors unless call_local; host applies drink with a normal call.
		if requesting_peer_id == multiplayer.get_unique_id():
			player_node.apply_inventory_drink(amount)
		else:
			player_node.apply_inventory_drink.rpc_id(requesting_peer_id, amount)


func _is_local_player_inventory_for_peer(inv: EntityInventory, peer_id: int) -> bool:
	var p: Node = PlayerService.get_player_node_or_null(peer_id)
	if p == null or not p.has_method("get_inventory"):
		return false
	return p.get_inventory() == inv


func _apply_split(op: Dictionary) -> void:
	var path: NodePath = op.get("path", NodePath(""))
	var row := int(op.get("row", 0))
	var col := int(op.get("col", 0))
	var guid := str(op.get("guid", ""))
	var inv := get_node_or_null(path)
	if not (inv is EntityInventory):
		return
	if not _validate_slot_occupant(inv, row, col, guid):
		return
	var item := ItemService.get_item(guid)
	if item == null or item.quantity < 2:
		return
	var take_qty: int = item.quantity >> 1
	if take_qty <= 0:
		return
	var new_guid := ItemService.split_off_quantity(guid, take_qty)
	if new_guid == "":
		return
	var cell := InventoryOps.find_free_cell(inv.slots, inv.rows, inv.columns)
	if cell.is_empty():
		ItemService.merge_into(guid, new_guid)
		return
	var ns := InventoryOps.clone_slots(InventoryOps.sanitize_slots(inv.slots))
	ns.append({"row": cell.row, "col": cell.col, "item_guid": new_guid})
	inv.update_slots(ns)


func _apply_quick_stack(op: Dictionary) -> void:
	var from_path: NodePath = op.get("from_path", NodePath(""))
	var to_path: NodePath = op.get("to_path", NodePath(""))
	var fr := int(op.get("fr", 0))
	var fc := int(op.get("fc", 0))
	var guid := str(op.get("guid", ""))
	var from_inv := get_node_or_null(from_path)
	var to_inv := get_node_or_null(to_path)
	if not (from_inv is EntityInventory) or not (to_inv is EntityInventory):
		return
	if not _validate_slot_occupant(from_inv, fr, fc, guid):
		return

	var merge_slot := _find_merge_target(to_inv, guid)
	if not merge_slot.is_empty():
		var m_row := int(merge_slot.row)
		var m_col := int(merge_slot.col)
		var to_guid := str(merge_slot.item_guid)
		_apply_merge(from_inv, fr, fc, guid, to_inv, m_row, m_col, to_guid)
		return

	var free := InventoryOps.find_free_cell(to_inv.slots, to_inv.rows, to_inv.columns)
	if free.is_empty():
		return
	_apply_move_to_empty(from_inv, fr, fc, guid, to_inv, int(free.row), int(free.col))


func _apply_move_pair(op: Dictionary) -> void:
	var from_path: NodePath = op.get("from_path", NodePath(""))
	var to_path: NodePath = op.get("to_path", NodePath(""))
	var fr := int(op.get("fr", 0))
	var fc := int(op.get("fc", 0))
	var to_row := int(op.get("tr", 0))
	var to_col := int(op.get("tc", 0))
	var from_guid := str(op.get("from_guid", ""))
	var from_inv := get_node_or_null(from_path)
	var to_inv := get_node_or_null(to_path)
	if not (from_inv is EntityInventory) or not (to_inv is EntityInventory):
		return
	if not _validate_slot_occupant(from_inv, fr, fc, from_guid):
		return
	var dest := InventoryOps.get_slot_at(to_inv.slots, to_row, to_col)
	if dest.is_empty():
		_apply_move_to_empty(from_inv, fr, fc, from_guid, to_inv, to_row, to_col)
		return
	var to_guid := str(dest.item_guid)
	if _can_merge(from_guid, to_guid):
		_apply_merge(from_inv, fr, fc, from_guid, to_inv, to_row, to_col, to_guid)
	else:
		_apply_swap(from_inv, fr, fc, to_inv, to_row, to_col)


func _validate_slot_occupant(inv: EntityInventory, row: int, col: int, guid: String) -> bool:
	if not InventoryOps.is_in_bounds(row, col, inv.rows, inv.columns):
		return false
	var s := InventoryOps.get_slot_at(inv.slots, row, col)
	if s.is_empty():
		return false
	return str(s.item_guid) == guid


func _can_merge(a_guid: String, b_guid: String) -> bool:
	if a_guid == b_guid:
		return false
	var a := ItemService.get_item(a_guid)
	var b := ItemService.get_item(b_guid)
	if a == null or b == null:
		return false
	return a.item_id == b.item_id and a.stackable and b.stackable and b.quantity < b.max_stack


func _find_merge_target(inv: EntityInventory, source_guid: String) -> Dictionary:
	var src := ItemService.get_item(source_guid)
	if src == null:
		return {}
	for slot in inv.slots:
		var dg := str(slot.item_guid)
		if dg == source_guid:
			continue
		var di := ItemService.get_item(dg)
		if di and di.item_id == src.item_id and di.stackable and src.stackable and di.quantity < di.max_stack:
			return slot
	return {}


func _apply_merge(from_inv: EntityInventory, _fr: int, _fc: int, from_guid: String, _to_inv: EntityInventory, _to_row: int, _to_col: int, to_guid: String) -> void:
	if from_guid == to_guid:
		return
	var did_merge := false
	while true:
		var dst_item := ItemService.get_item(to_guid)
		var src_item := ItemService.get_item(from_guid)
		if dst_item == null or src_item == null:
			break
		if dst_item.quantity >= dst_item.max_stack:
			break
		var res := ItemService.merge_into(to_guid, from_guid)
		if int(res.get("merged", 0)) <= 0:
			break
		did_merge = true
		if bool(res.get("from_depleted", false)):
			var ns_from := InventoryOps.remove_slot_with_guid(from_inv.slots, from_guid)
			from_inv.update_slots(ns_from)
			break
	if did_merge:
		# Destination (and partial source) stacks change only in ItemService; slot list may be unchanged.
		from_inv.notify_display_refresh.rpc()
		_to_inv.notify_display_refresh.rpc()


func _apply_swap(from_inv: EntityInventory, fr: int, fc: int, to_inv: EntityInventory, to_row: int, to_col: int) -> void:
	if from_inv == to_inv:
		var res := InventoryOps.swap_slots_same_inventory(from_inv.slots, fr, fc, to_row, to_col, from_inv.rows, from_inv.columns)
		if res.ok:
			from_inv.update_slots(res.slots)
		return
	var cx := InventoryOps.cross_swap(from_inv.slots, fr, fc, to_inv.slots, to_row, to_col, from_inv.rows, from_inv.columns, to_inv.rows, to_inv.columns)
	if cx.ok:
		from_inv.update_slots(cx.from_slots)
		to_inv.update_slots(cx.to_slots)


func _apply_move_to_empty(from_inv: EntityInventory, fr: int, fc: int, from_guid: String, to_inv: EntityInventory, to_row: int, to_col: int) -> void:
	if from_inv == to_inv:
		var res := InventoryOps.move_slot_to_empty(from_inv.slots, fr, fc, to_row, to_col, from_inv.rows, from_inv.columns)
		if res.ok:
			from_inv.update_slots(res.slots)
		return
	var cx := InventoryOps.cross_move_to_empty(from_inv.slots, fr, fc, to_inv.slots, to_row, to_col, from_guid, from_inv.rows, from_inv.columns, to_inv.rows, to_inv.columns)
	if cx.ok:
		from_inv.update_slots(cx.from_slots)
		to_inv.update_slots(cx.to_slots)

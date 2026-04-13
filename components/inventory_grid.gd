extends GridContainer
class_name InventoryGrid

var inventory_item_node := preload("res://components/ui_inventory_slot.tscn")

signal inventory_slot_hover_changed(inventory: EntityInventory, slot: Dictionary, hovering: bool)

var _current_inventory: EntityInventory
var _on_slot_activated: Callable = Callable()
var _hover: Dictionary = {}


func refresh(inventory: EntityInventory, on_slot_activated: Callable) -> void:
	_hover = {}
	_current_inventory = inventory
	_on_slot_activated = on_slot_activated
	var hover_cb := Callable(self, "_forward_hover")
	for row_num in range(inventory.rows):
		for col_num in range(inventory.columns):
			var slot_node := get_item_slot_node(row_num, col_num)
			if slot_node == null:
				var slot_id := get_item_slot_id(row_num, col_num)
				slot_node = inventory_item_node.instantiate()
				slot_node.name = slot_id
				slot_node.slot_activated.connect(_forward_activation)
				slot_node.slot_hover_changed.connect(hover_cb)
				add_child(slot_node, true)
			elif not slot_node.slot_hover_changed.is_connected(hover_cb):
				slot_node.slot_hover_changed.connect(hover_cb)
			slot_node.bound_inventory = inventory
			slot_node.item_slot = {"row": row_num, "col": col_num}
	for sl in inventory.slots:
		var slot_node := get_item_slot_node(int(sl.row), int(sl.col))
		if slot_node == null:
			print("cant render item into inventory: r", sl.row, "c", sl.col)
			continue
		slot_node.item_slot = sl.duplicate()
	columns = inventory.columns


func _forward_activation(slot: Dictionary, button_index: int, shift_pressed: bool, ctrl_pressed: bool) -> void:
	if _current_inventory != null and _on_slot_activated.is_valid():
		_on_slot_activated.call(_current_inventory, slot, button_index, shift_pressed, ctrl_pressed)


func _forward_hover(slot: Dictionary, hovering: bool, inventory: EntityInventory) -> void:
	if inventory != _current_inventory:
		return
	if hovering:
		_hover = {"row": int(slot.get("row", 0)), "col": int(slot.get("col", 0)), "guid": str(slot.get("item_guid", ""))}
		inventory_slot_hover_changed.emit(inventory, slot, true)
	else:
		if _hover.get("row", -1) == int(slot.get("row", -2)) and _hover.get("col", -1) == int(slot.get("col", -2)):
			_hover = {}
			inventory_slot_hover_changed.emit(inventory, slot, false)


func get_item_slot_id(row: int, col: int) -> String:
	return "r" + str(row) + "c" + str(col)


func get_item_slot_node(row: int, col: int) -> UIInventorySlot:
	var slot_id = get_item_slot_id(row, col)
	return get_node_or_null(slot_id)

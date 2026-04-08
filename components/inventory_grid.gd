extends GridContainer
class_name InventoryGrid

var inventory_item_node := preload("res://components/ui_inventory_slot.tscn")

var _current_inventory: EntityInventory
var _on_slot_activated: Callable = Callable()


func refresh(inventory: EntityInventory, on_slot_activated: Callable) -> void:
	_current_inventory = inventory
	_on_slot_activated = on_slot_activated
	for row_num in range(inventory.rows):
		for col_num in range(inventory.columns):
			var slot_node := get_item_slot_node(row_num, col_num)
			if slot_node == null:
				var slot_id := get_item_slot_id(row_num, col_num)
				slot_node = inventory_item_node.instantiate()
				slot_node.name = slot_id
				slot_node.slot_activated.connect(_forward_activation)
				add_child(slot_node, true)
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


func get_item_slot_id(row: int, col: int) -> String:
	return "r" + str(row) + "c" + str(col)


func get_item_slot_node(row: int, col: int) -> UIInventorySlot:
	var slot_id = get_item_slot_id(row, col)
	return get_node_or_null(slot_id)

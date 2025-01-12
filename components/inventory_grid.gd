extends GridContainer
class_name InventoryGrid

var inventory_item_node := preload("res://components/ui_inventory_slot.tscn")

func refresh(inventory: InventoryData, on_slot_connected):
	for row_num in range(inventory.rows):
		for col_num in range(inventory.columns):
			# get or create slot node
			var slot_node := get_item_slot_node(row_num, col_num)
			if !slot_node:
				var slot_id := get_item_slot_id(row_num, col_num)
				slot_node = inventory_item_node.instantiate()
				slot_node.name = slot_id
				slot_node.connect("slot_selected", on_slot_connected)
				add_child(slot_node, true);
			# reset state of slot node
			slot_node.item_slot = ItemSlot.new()
	# set slots with items
	for slot in inventory.slots:
		var slot_node := get_item_slot_node(slot.row, slot.col)
		if slot_node == null:
			print("cant render item into inventory: r", slot.row, "c", slot.col)
			continue
		slot_node.item_slot = slot
	# set slot grid columns
	columns = inventory.columns
	
func get_item_slot_id(row: int, col: int) -> String:
	return "r" + str(row) + "c" + str(col)
	
func get_item_slot_node(row: int, col: int) -> UIInventorySlot:
	var slot_id = get_item_slot_id(row, col)
	return get_node_or_null(slot_id)

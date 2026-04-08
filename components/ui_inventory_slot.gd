extends Button
class_name UIInventorySlot

signal slot_selected(slot: Dictionary)

@export
var item_slot: Dictionary :
	set(input): 
		item_slot = input
		refresh()
	get:
		return item_slot

func refresh():
	if not is_node_ready():
		await ready
	var empty_item = {
		"icon": load("res://items/resources/empty.png"),
		"quantity": 0,
		"formatted_name": "EMPTY"
	}
	var item = empty_item
	if item_slot.has("item_guid"):
		var resolved_item = ItemService.get_item(str(item_slot.item_guid))
		if resolved_item != null:
			item = resolved_item
		
	var texture = item.icon
	var quantity = item.quantity
	$Icon.texture = texture
	if quantity == 0:
		$Quantity.text = ""
	else:
		$Quantity.text = str(quantity)

func _on_pressed():
	slot_selected.emit(item_slot)
  

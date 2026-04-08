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
	var item = {
		"icon": load("res://items/resources/empty.png"),
		"quantity": 0,
		"formatted_name": "EMPTY"
	}
	if item_slot.has("item_guid"):
		item = ItemService.get_item(item_slot.item_guid)
		
	var texture = item.icon
	var quantity = item.quantity
	var _name = item.formatted_name
	$Icon.texture = texture
	if quantity == 0:
		$Quantity.text = ""
	else:
		$Quantity.text = str(quantity)

func _on_pressed():
	slot_selected.emit(item_slot)
  

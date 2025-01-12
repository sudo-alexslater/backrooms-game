extends Button
class_name UIInventorySlot

signal slot_selected(slot: ItemSlot)

@export
var item_slot: ItemSlot :
	set(input): 
		item_slot = input
		refresh()
	get:
		return item_slot

func refresh():
	if not is_node_ready():
		await ready
	var texture = item_slot.item.icon
	var quantity = item_slot.item.quantity
	var _name = item_slot.item.formatted_name
	$Icon.texture = texture
	if quantity == 0:
		$Quantity.text = ""
	else:
		$Quantity.text = str(quantity)

func _on_pressed():
	slot_selected.emit(item_slot)
  

extends Node2D

func _ready():
	# generate up to 10 random items, but at least 2
	for indx in randi_range(2, 10):
		var random_item_guid = ItemService.new_random_item()
		$ItemInventoryComponent.inventory.add_slot(ItemSlot.new({
			"row": 0, 
			"col": 0,
			"item_guid": random_item_guid
		}))
func _on_item_selected(slot: ItemSlot, interactor: Node):
	# if the interactor has an inventory component transfer into it
	var component: Node = get_node_or_null(str(interactor.get_path()) + "/PlayerInventoryComponent")
	if component:
		component.inventory.add_slot(slot)
		$ItemInventoryComponent.inventory.remove_slot_with_id(slot.item.guid)
	else:
		print("ERROR: interactor does not have a player inventory component")

func init(options: Dictionary): 
	pass

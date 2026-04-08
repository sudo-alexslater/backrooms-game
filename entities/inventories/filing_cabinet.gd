extends Node3D


func _ready():
	# generate up to 10 random items, but at least 2
	if NetworkService.is_authority():
		for indx in randi_range(2, 10):
			var random_item_guid = ItemService.new_random_item()
			$ItemInventoryComponent/EntityInventory.add_slot({
				"row": 0, 
				"col": 0,
				"item_guid": random_item_guid
			})
func _on_item_selected(slot: Dictionary, interactor: Node):
	if not slot.has("item_guid"):
		return 
	# if the interactor has an inventory component transfer into it
	var component: Node = get_node_or_null(str(interactor.get_path()) + "/PlayerInventoryComp/EntityInventory")
	if component:
		component.add_slot(slot)
		$ItemInventoryComponent/EntityInventory.remove_slot_with_id(slot.item_guid)
	else:
		print("ERROR: interactor does not have a player inventory component")

func init(state: EntityState):
	pass

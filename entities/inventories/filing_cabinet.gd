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
	$ItemInventoryComponent.request_transfer_to_interactor(slot, interactor)

func init(_state: EntityState):
	pass

extends Node3D


func _ready() -> void:
	if NetworkService.is_authority():
		for _i in randi_range(2, 10):
			var random_item_guid := ItemService.new_random_item()
			$ItemInventoryComponent.get_inventory().authority_place_item_first_free(random_item_guid)


func get_inventory() -> EntityInventory:
	return $ItemInventoryComponent.get_inventory()


func init(_state: EntityState) -> void:
	pass

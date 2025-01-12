extends Node2D

@export
var player_state: PlayerState :
	set(input): 
		player_state = input
		$ItemInventoryComponent.inventory_text = "The Corpse of " + player_state.name
	get:
		return player_state

func _on_item_selected(slot, interactor):
	# if the interactor has an inventory component transfer into it
	var component: Node = get_node_or_null(str(interactor.get_path()) + "/PlayerInventoryComponent")
	if component:
		component.inventory.add_slot(slot)
		$ItemInventoryComponent.inventory.remove_slot_with_id(slot.item.guid)
	else:
		print("ERROR: interactor does not have a player inventory component")

# ==================
# Entity System
# ==================
func init(from_dict: Dictionary = {}):
	if !from_dict.is_empty():
		if from_dict.has("player_state"):
			player_state = PlayerState.new(from_dict.player_state)
		if from_dict.has("inventory"):
			$ItemInventoryComponent.inventory = InventoryData.new(from_dict.inventory)
	

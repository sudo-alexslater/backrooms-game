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
func init(state: EntityState):
	var options := state.options
	if options.has("player_state"):
		player_state = PlayerState.new(options.player_state)
	if state.options.has("inventory"):
		$ItemInventoryComponent.inventory = InventoryData.new(options.inventory)
	

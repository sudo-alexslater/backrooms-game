extends Node3D

@export
var player_state: PlayerState :
	set(input):
		player_state = input
		$ItemInventoryComponent.inventory_text = "The Corpse of " + player_state.name
	get:
		return player_state

func _on_item_selected(slot: Dictionary, interactor: Node):
	if not slot.has("item_guid"):
		return
	var component: Node = get_node_or_null(str(interactor.get_path()) + "/PlayerInventoryComp/EntityInventory")
	if component:
		component.add_slot(slot)
		$ItemInventoryComponent/EntityInventory.remove_slot_with_id(slot.item_guid)
	else:
		print("ERROR: interactor does not have a player inventory component")

# ==================
# Entity System
# ==================
func init(state: EntityState):
	var options := state.options
	if options.has("player_state"):
		player_state = PlayerState.new(options.player_state)
	if options.has("inventory"):
		$ItemInventoryComponent/EntityInventory.init(options.inventory)

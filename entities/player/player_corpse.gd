extends Node3D

@export
var player_state: PlayerState :
	set(input):
		player_state = input
		$ItemInventoryComponent.inventory_text = "The Corpse of " + player_state.name
	get:
		return player_state

func _on_item_selected(slot: Dictionary, interactor: Node):
	$ItemInventoryComponent.request_transfer_to_interactor(slot, interactor)

# ==================
# Entity System
# ==================
func init(state: EntityState):
	var options := state.options
	if options.has("player_state"):
		player_state = PlayerState.new(options.player_state)
	if options.has("inventory"):
		$ItemInventoryComponent/EntityInventory.init(options.inventory)

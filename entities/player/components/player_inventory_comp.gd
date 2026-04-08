extends Node


@export
var inventory_text := "Player Inventory"
@export
var inventory_gui_enabled := true
@onready 
var inventory_grid_node: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready
var title = $Window/Panel/MarginContainer/VBox/Title

func _ready():
	close()
	refresh()

func _input(event):
	if Input.is_action_just_pressed("toggle_inventory") and inventory_gui_enabled:
		refresh()
		if $Window.visible:
			close()
		else:
			open()
	if Input.is_action_just_pressed("escape") && $Window.visible:
		close()

@rpc("any_peer", "call_local")
func refresh():
	title.text = inventory_text
	inventory_grid_node.refresh($EntityInventory, on_slot_selected)

func open():
	$Window.show()
	PlayerGui.dialog_has_opened("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func close():
	$Window.hide()
	PlayerGui.dialog_has_closed("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func on_slot_selected(item: Dictionary):
	GameLogger.debug("Item selected: " + item.item_guid)

func _on_entity_inventory_updated() -> void:
	refresh()

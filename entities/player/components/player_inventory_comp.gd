extends Node

@export
var inventory: InventoryData
@export
var inventory_text := "Player Inventory"
@export
var inventory_gui_enabled := true
@onready 
var inventory_grid_node: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready
var title = $Window/Panel/MarginContainer/VBox/Title

func _ready():
	inventory.inventory_updated.connect(on_inventory_updated)
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
func refresh(inventory_dict: Dictionary = {}):
	if inventory_dict == null:
		inventory = InventoryData.new(inventory_dict)
	title.text = inventory_text
	inventory_grid_node.refresh(inventory, on_slot_selected)

func open():
	$Window.show()
	PlayerGui.dialog_has_opened("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func close():
	$Window.hide()
	PlayerGui.dialog_has_closed("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func on_slot_selected(item: ItemSlot):
	Logger.debug("Item selected: " + item.item_guid)

func on_inventory_updated():
	refresh.rpc(inventory.to_dict())

extends Node3D
class_name ItemInventoryComponent

signal item_selected(slot: Dictionary, interactor: Node)

@export var inventory_text := "DEFAULT TEXT"

@onready var inventory_grid: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready var title: Label = $Window/Panel/MarginContainer/VBox/Title
var interacting_entity: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	close()
	refresh()
	
func _process(_delta):
	if Input.is_action_just_pressed("escape") && $Window.visible:
		close()

func refresh():
	inventory_grid.refresh($EntityInventory, on_slot_selected)
	title.text = inventory_text

func open():
	PlayerGui.dialog_has_opened("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Window.show()	
	
func close():
	interacting_entity = null
	PlayerGui.dialog_has_closed("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Window.hide()

func interact(interactor: Node): 
	interacting_entity = interactor
	open()
	
func get_interaction_details(): 
	return {}

func get_inventory() -> EntityInventory:
	return $EntityInventory

func get_transfer_service() -> Node:
	return get_node_or_null("/root/InventoryTransferService")

func request_transfer_to_interactor(slot: Dictionary, interactor: Node) -> bool:
	if not slot.has("item_guid"):
		return false
	var transfer_service = get_transfer_service()
	if transfer_service == null:
		GameLogger.error("Transfer failed: InventoryTransferService unavailable")
		return false
	var from_inventory_path = get_inventory().get_path()
	var to_inventory_path = transfer_service.resolve_inventory_path_from_owner(interactor)
	if str(to_inventory_path).is_empty():
		GameLogger.error("Transfer failed: interactor has no inventory interface")
		return false
	return transfer_service.request_transfer_local(from_inventory_path, to_inventory_path, str(slot.item_guid))
	
func on_slot_selected(slot: Dictionary):
	item_selected.emit(slot, interacting_entity)

func _on_entity_inventory_updated() -> void:
	refresh()

extends Node3D
class_name ItemInventoryComponent

signal item_selected(slot: ItemSlot, interactor: Node)

@export var inventory: InventoryData
@export var inventory_text := "DEFAULT TEXT"
@onready var inventory_grid: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready var title: Label = $Window/Panel/MarginContainer/VBox/Title
var inventory_item_node := preload("res://components/ui_inventory_slot.tscn")
var interacting_entity: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	close()
	refresh.rpc(inventory.to_dict())
	
func _process(delta):
	if Input.is_action_just_pressed("escape") && $Window.visible:
		close()

@rpc("any_peer", "call_local")
func refresh(inventory_dict: Dictionary = {}):
	if !inventory_dict.is_empty():
		inventory = InventoryData.new(inventory_dict)
		inventory.inventory_updated.connect(on_inventory_updated)
	inventory_grid.refresh(inventory, on_slot_selected)
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
	
func on_slot_selected(slot: ItemSlot):
	item_selected.emit(slot, interacting_entity)

func on_inventory_updated():
	refresh.rpc(inventory.to_dict())

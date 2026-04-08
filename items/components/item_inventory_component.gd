extends Node3D
class_name ItemInventoryComponent

signal item_selected(slot: Dictionary, interactor: Node)

@export var inventory_text := "DEFAULT TEXT"

@onready var inventory_grid: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready var title: Label = $Window/Panel/MarginContainer/VBox/Title
var inventory_item_node := preload("res://components/ui_inventory_slot.tscn")
var interacting_entity: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	close()
	refresh()
	
func _process(delta):
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
	
func on_slot_selected(slot: Dictionary):
	item_selected.emit(slot, interacting_entity)

func _on_entity_inventory_updated() -> void:
	refresh()

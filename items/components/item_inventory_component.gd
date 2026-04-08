extends Node3D
class_name ItemInventoryComponent

const _InvPanelLayout = preload("res://components/inventory_panel_layout.gd")

@export var inventory_text := "DEFAULT TEXT"

@onready var inventory_grid: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready var title: Label = $Window/Panel/MarginContainer/VBox/Title
var interacting_entity: Node

var _paired_player_comp: Node = null
var _opened_backpack_for_pair: bool = false


func _ready() -> void:
	close()
	refresh()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("escape") and $Window.visible:
		close()


func refresh() -> void:
	inventory_grid.refresh($EntityInventory, on_slot_activated)
	title.text = inventory_text


func is_container_window_visible() -> bool:
	return $Window.visible


func open() -> void:
	InventoryTransferService.notify_external_inventory_opened($EntityInventory)
	PlayerGui.dialog_has_opened("container_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if interacting_entity is Player and interacting_entity.is_local_player:
		InventoryTransferService.register_local_container_ui(self)
		_try_pair_local_player_backpack()
	else:
		_InvPanelLayout.fullscreen($Window/Panel)
	$Window.show()


func _try_pair_local_player_backpack() -> void:
	if interacting_entity == null or not interacting_entity is Player or not interacting_entity.is_local_player:
		_InvPanelLayout.fullscreen($Window/Panel)
		return
	var pic: Node = interacting_entity.get_node_or_null("PlayerInventoryComp")
	if pic == null:
		_InvPanelLayout.fullscreen($Window/Panel)
		return
	_paired_player_comp = pic
	_opened_backpack_for_pair = not pic.is_backpack_visible()
	if _opened_backpack_for_pair:
		pic.open_for_container_pair(self)
	else:
		pic.notify_container_opened_alongside(self)
	_InvPanelLayout.right_half($Window/Panel)


func set_paired_player_comp(pic: Node) -> void:
	_paired_player_comp = pic
	_opened_backpack_for_pair = false
	_InvPanelLayout.right_half($Window/Panel)


func on_player_backpack_closed_while_paired() -> void:
	_paired_player_comp = null
	_opened_backpack_for_pair = false
	_InvPanelLayout.fullscreen($Window/Panel)


func close() -> void:
	InventoryTransferService.clear_active_pick()
	InventoryTransferService.notify_external_inventory_closed($EntityInventory)
	InventoryTransferService.unregister_local_container_ui(self)
	var pic: Node = _paired_player_comp
	var opened_for_pair: bool = _opened_backpack_for_pair
	_paired_player_comp = null
	_opened_backpack_for_pair = false
	interacting_entity = null
	$Window.hide()
	_InvPanelLayout.fullscreen($Window/Panel)
	PlayerGui.dialog_has_closed("container_inventory")
	if pic != null and is_instance_valid(pic):
		if opened_for_pair:
			pic.force_close_after_container()
		else:
			pic.end_container_pairing_restore_fullscreen_only()
	if not PlayerGui.has_open_dialog():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func interact(interactor: Node) -> void:
	interacting_entity = interactor
	open()


func get_interaction_details() -> Dictionary:
	return {}


func get_inventory() -> EntityInventory:
	return $EntityInventory


func on_slot_activated(inventory: EntityInventory, slot: Dictionary, button_index: int, shift_pressed: bool, ctrl_pressed: bool) -> void:
	InventoryTransferService.handle_ui_slot_input(inventory, slot, button_index, shift_pressed, ctrl_pressed, self)


func _on_entity_inventory_updated() -> void:
	refresh()

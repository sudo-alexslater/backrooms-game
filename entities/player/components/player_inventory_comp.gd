extends Node

const _InvPanelLayout = preload("res://components/inventory_panel_layout.gd")

@export
var inventory_text := "Player Inventory"
@export
var inventory_gui_enabled := true
@onready
var inventory_grid_node: InventoryGrid = $Window/Panel/MarginContainer/VBox/HBox/InventoryGrid
@onready
var title = $Window/Panel/MarginContainer/VBox/Title

var _paired_container: ItemInventoryComponent = null
var _hovered: Dictionary = {}


func _ready() -> void:
	close()
	refresh()
	inventory_grid_node.inventory_slot_hover_changed.connect(_on_inventory_slot_hover)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_inventory") and inventory_gui_enabled:
		refresh()
		if $Window.visible:
			close()
		else:
			open()
	if Input.is_action_just_pressed("interact") and $Window.visible and inventory_gui_enabled:
		if _try_consume_hovered_item():
			get_viewport().set_input_as_handled()
			return
	if Input.is_action_just_pressed("escape") and $Window.visible:
		close()


func refresh() -> void:
	title.text = inventory_text
	inventory_grid_node.refresh($EntityInventory, on_slot_activated)


func is_backpack_visible() -> bool:
	return $Window.visible


func open() -> void:
	$Window.show()
	PlayerGui.dialog_has_opened("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var container: Node = InventoryTransferService.active_local_container_ui
	if container is ItemInventoryComponent and is_instance_valid(container) and container.is_container_window_visible():
		_paired_container = container
		container.set_paired_player_comp(self)
		_InvPanelLayout.left_half($Window/Panel)
	else:
		_paired_container = null
		_InvPanelLayout.fullscreen($Window/Panel)
	refresh()


func open_for_container_pair(container: ItemInventoryComponent) -> void:
	_paired_container = container
	$Window.show()
	PlayerGui.dialog_has_opened("player_inventory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_InvPanelLayout.left_half($Window/Panel)
	refresh()


func notify_container_opened_alongside(container: ItemInventoryComponent) -> void:
	_paired_container = container
	_InvPanelLayout.left_half($Window/Panel)
	refresh()


func close() -> void:
	InventoryTransferService.clear_active_pick()
	if _paired_container != null and is_instance_valid(_paired_container) and _paired_container.is_container_window_visible():
		_paired_container.on_player_backpack_closed_while_paired()
	_paired_container = null
	$Window.hide()
	_InvPanelLayout.fullscreen($Window/Panel)
	PlayerGui.dialog_has_closed("player_inventory")
	if not PlayerGui.has_open_dialog():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func end_container_pairing_restore_fullscreen_only() -> void:
	_paired_container = null
	if not $Window.visible:
		return
	_InvPanelLayout.fullscreen($Window/Panel)
	refresh()


func force_close_after_container() -> void:
	_paired_container = null
	InventoryTransferService.clear_active_pick()
	$Window.hide()
	_InvPanelLayout.fullscreen($Window/Panel)
	PlayerGui.dialog_has_closed("player_inventory")


func get_inventory() -> EntityInventory:
	return $EntityInventory


func on_slot_activated(inventory: EntityInventory, slot: Dictionary, button_index: int, shift_pressed: bool, ctrl_pressed: bool) -> void:
	InventoryTransferService.handle_ui_slot_input(inventory, slot, button_index, shift_pressed, ctrl_pressed, null)


func _on_inventory_slot_hover(inv: EntityInventory, slot: Dictionary, hovering: bool) -> void:
	if hovering:
		_hovered = {"inv": inv, "slot": slot.duplicate(true)}
	else:
		_hovered = {}


func _try_consume_hovered_item() -> bool:
	if _hovered.is_empty():
		return false
	var inv: EntityInventory = _hovered.get("inv", null)
	var slot: Dictionary = _hovered.get("slot", {})
	if inv == null or slot.is_empty():
		return false
	var guid := str(slot.get("item_guid", ""))
	if guid.is_empty():
		return false
	var item = ItemService.get_item(guid)
	if item == null or not ItemService.CONSUMABLE_THIRST_RESTORE.has(item.item_id):
		return false
	InventoryTransferService.request_consume_item_local(inv, slot)
	return true


func _on_entity_inventory_updated() -> void:
	_hovered = {}
	refresh()

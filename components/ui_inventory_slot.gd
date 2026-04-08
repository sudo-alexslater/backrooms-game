extends Button
class_name UIInventorySlot

signal slot_activated(slot: Dictionary, button_index: int, shift_pressed: bool, ctrl_pressed: bool)

## Set by InventoryGrid for drag-and-drop between inventories.
var bound_inventory: EntityInventory

@export
var item_slot: Dictionary :
	set(input):
		item_slot = input
		refresh()
	get:
		return item_slot


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE


func refresh() -> void:
	if not is_node_ready():
		await ready
	var empty_item = {
		"icon": load("res://items/resources/empty.png"),
		"quantity": 0,
		"formatted_name": "EMPTY"
	}
	var item = empty_item
	if item_slot.has("item_guid") and str(item_slot.item_guid) != "":
		var resolved_item = ItemService.get_item(str(item_slot.item_guid))
		if resolved_item != null:
			item = resolved_item

	var texture = item.icon
	var quantity = item.quantity
	$Icon.texture = texture
	if quantity == 0:
		$Quantity.text = ""
	else:
		$Quantity.text = str(quantity)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
		slot_activated.emit(item_slot, mb.button_index, mb.shift_pressed, mb.ctrl_pressed)
		accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if bound_inventory == null:
		return null
	if not item_slot.has("item_guid") or str(item_slot.item_guid) == "":
		return null
	var preview := TextureRect.new()
	preview.texture = $Icon.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(72, 72)
	set_drag_preview(preview)
	return {
		"type": "inventory_slot",
		"path": bound_inventory.get_path(),
		"row": int(item_slot.get("row", 0)),
		"col": int(item_slot.get("col", 0)),
		"guid": str(item_slot.item_guid)
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if bound_inventory == null:
		return false
	if data is Dictionary and str(data.get("type", "")) == "inventory_slot":
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if bound_inventory == null:
		return
	if not data is Dictionary:
		return
	if str(data.get("type", "")) != "inventory_slot":
		return
	InventoryTransferService.clear_active_pick()
	var from_path: NodePath = data.get("path", NodePath(""))
	var fr: int = int(data.get("row", 0))
	var fc: int = int(data.get("col", 0))
	var from_guid: String = str(data.get("guid", ""))
	var to_row: int = int(item_slot.get("row", 0))
	var to_col: int = int(item_slot.get("col", 0))
	if from_path == bound_inventory.get_path() and fr == to_row and fc == to_col:
		return
	InventoryTransferService.request_slot_operation_local({
		"type": "move_pair",
		"from_path": from_path,
		"fr": fr,
		"fc": fc,
		"from_guid": from_guid,
		"to_path": bound_inventory.get_path(),
		"tr": to_row,
		"tc": to_col
	})

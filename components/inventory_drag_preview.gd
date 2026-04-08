extends CanvasLayer

## Follows the mouse while the player has an inventory item "picked" for move/merge/swap.

@onready var _drag_root: Control = $DragRoot
@onready var _icon: TextureRect = $DragRoot/Icon
@onready var _qty: Label = $DragRoot/Quantity


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_drag_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide_preview()


func show_for_item_guid(guid: String) -> void:
	var item = ItemService.get_item(guid)
	if item == null:
		_icon.texture = load("res://items/resources/empty.png")
		_qty.text = ""
	else:
		_icon.texture = item.icon
		_qty.text = "" if item.quantity <= 0 else str(item.quantity)
	_drag_root.modulate = Color(1, 1, 1, 0.92)
	_drag_root.visible = true
	set_process(true)
	_update_position()


func hide_preview() -> void:
	_drag_root.visible = false
	set_process(false)


func _process(_delta: float) -> void:
	if not _drag_root.visible:
		return
	_update_position()


func _update_position() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	_drag_root.global_position = vp.get_mouse_position() - _drag_root.size * 0.5

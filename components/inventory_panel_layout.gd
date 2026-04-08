extends RefCounted
class_name InventoryPanelLayout


static func fullscreen(panel: Control) -> void:
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0


static func left_half(panel: Control, margin: float = 10.0) -> void:
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 1.0
	panel.offset_left = margin
	panel.offset_top = margin
	panel.offset_right = -margin * 0.5
	panel.offset_bottom = -margin


static func right_half(panel: Control, margin: float = 10.0) -> void:
	panel.anchor_left = 0.5
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = margin * 0.5
	panel.offset_top = margin
	panel.offset_right = -margin
	panel.offset_bottom = -margin

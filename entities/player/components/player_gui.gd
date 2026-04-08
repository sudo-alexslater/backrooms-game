extends CanvasLayer

enum GUIScene {
	Main,
	Death
}

const INVENTORY_DIALOG_IDS: Array[String] = ["player_inventory", "container_inventory"]

var _inventory_ui_depth: int = 0


func _ready() -> void:
	hide()
	reset()


func on_health_changed(_old_value, new_value) -> void:
	$HUD/Bars/Health/Gauge.value = new_value
	$HUD/Bars/Health/Count/Background/Number.text = str(new_value)


func on_thirst_changed(_old_value, new_value) -> void:
	$HUD/Bars/Thirst/Gauge.value = new_value
	$HUD/Bars/Thirst/Count/Background/Number.text = str(new_value)


func on_health_depleted() -> void:
	switch_scene(GUIScene.Death)


func show_HUD() -> void:
	$HUD.show()


func hide_HUD() -> void:
	$HUD.hide()


func show_death() -> void:
	$DeathScene.show()


func hide_death() -> void:
	$DeathScene.hide()


func reset() -> void:
	_inventory_ui_depth = 0
	for id in INVENTORY_DIALOG_IDS:
		open_dialogs.erase(id)
	switch_scene(GUIScene.Main)


func switch_scene(scene: GUIScene) -> void:
	if scene == GUIScene.Main:
		hide_death()
		if _inventory_ui_depth > 0:
			hide_HUD()
		else:
			show_HUD()
	if scene == GUIScene.Death:
		_inventory_ui_depth = 0
		for id in INVENTORY_DIALOG_IDS:
			open_dialogs.erase(id)
		hide_HUD()
		show_death()


var open_dialogs: Dictionary = {}


func dialog_has_opened(dialog_name: String) -> void:
	open_dialogs[dialog_name] = true
	if dialog_name in INVENTORY_DIALOG_IDS:
		_inventory_ui_depth += 1
		if _inventory_ui_depth == 1 and not $DeathScene.visible:
			hide_HUD()


func dialog_has_closed(dialog_name: String) -> void:
	open_dialogs[dialog_name] = false
	if dialog_name in INVENTORY_DIALOG_IDS:
		_inventory_ui_depth = maxi(0, _inventory_ui_depth - 1)
		if _inventory_ui_depth == 0 and not $DeathScene.visible:
			show_HUD()


func has_open_dialog() -> bool:
	for dialog_name in open_dialogs:
		if open_dialogs[dialog_name]:
			return true
	return false

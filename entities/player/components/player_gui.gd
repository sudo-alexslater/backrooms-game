extends CanvasLayer

enum GUIScene {
	Main,
	Death
}

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	reset()

func on_health_changed(_old_value, new_value):
	$HUD/Bars/Health/Gauge.value = new_value
	$HUD/Bars/Health/Count/Background/Number.text = str(new_value)
func on_thirst_changed(_old_value, new_value):
	$HUD/Bars/Thirst/Gauge.value = new_value
	$HUD/Bars/Thirst/Count/Background/Number.text = str(new_value)
func on_health_depleted():
	switch_scene(GUIScene.Death)

func show_HUD():
	$HUD.show()
func hide_HUD():
	$HUD.hide()
func show_death():
	$DeathScene.show()
func hide_death():
	$DeathScene.hide()

func reset(): 
	switch_scene(GUIScene.Main)

func switch_scene(scene: GUIScene):
	if scene == GUIScene.Main:
		show_HUD()
		hide_death()
	if scene == GUIScene.Death:
		hide_HUD()
		show_death()

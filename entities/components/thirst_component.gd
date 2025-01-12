extends Node
class_name ThirstComponent

signal thirst_changed(old_value: int, new_value: int)
signal thirst_depleted

@export
var health: HealthComponent
@export
var max_thirst := 20
@export
var thirsting_amount := 1
@export
var thirst_hurt_amount := 1
@export
var disabled := false :
	set(input):
		disabled = input
		$Timer.process_mode 
var thirst := max_thirst


func _ready():
	thirst_changed.emit(thirst, thirst)
	
func reset():
	drink(max_thirst)

func _on_thirst_tick():
	var new_thirst := thirst - thirsting_amount
	if new_thirst <= 0:
		new_thirst = 0
		thirst_depleted.emit()
		health.hurt(thirst_hurt_amount)
	thirst_changed.emit(thirst, new_thirst)
	thirst = new_thirst

func drink(amount):
	thirst += amount;
	if thirst > max_thirst:
		thirst = max_thirst
	thirst_changed.emit(0, thirst)

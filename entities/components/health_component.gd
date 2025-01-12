extends Node
class_name HealthComponent

signal health_changed(old_value: int, new_value: int)
signal health_depleted

@export
var max_hp := 100
@export
var hp := max_hp
@export
var disabled := false 
var is_health_depleted := false

# Called when the node enters the scene tree for the first time.
func _ready():
	health_changed.emit(hp, hp)
	
func reset():
	heal(max_hp)
	is_health_depleted = false
	
func is_dead():
	if hp <= 0:
		return true
	return false

func hurt(amount: int):
	if is_health_depleted:
		return
		
	var new_hp = hp - amount;
	health_changed.emit(hp, new_hp)
	
	if(new_hp <= 0):
		new_hp = 0
		is_health_depleted = true
		health_depleted.emit()
	hp = new_hp
	
func heal(amount: int):
	is_health_depleted = false
	var new_hp := hp + amount;
	if new_hp > max_hp:
		new_hp = max_hp
	health_changed.emit(hp, new_hp)
	hp = new_hp



extends Node2D

func get_interaction_details():
	return {
		"name": "Almond Water",
		"effect": "thirst",
		"effect_value": 100
	}
func interact():
	queue_free()

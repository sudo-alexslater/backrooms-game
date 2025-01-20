extends WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# test item drop 
	EntityService.add_entity({
			"guid": IDService.v4(),
			"initial_position": Vector3(0, 0, 0),
			"node_path": "res://entities/inventories/filing_cabinet.tscn"
		})

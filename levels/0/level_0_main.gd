extends WorldEnvironment

const IDServiceScript = preload("res://services/id_service.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# test item drop 
	if NetworkService.is_authority():
		EntityService.add_entity({
				"guid": IDServiceScript.v4(),
				"initial_position": Vector3(0, 0, 0),
				"node_path": "res://entities/inventories/filing_cabinet.tscn"
			})

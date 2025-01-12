extends Node2D
class_name SpawnPoint

enum SpawnPointType {
	Enemy,
	Player
}

@export
var type: SpawnPointType = SpawnPointType.Player

# Called when the node enters the scene tree for the first time.
func _ready():
	EntityService.register_spawnpoint(self)

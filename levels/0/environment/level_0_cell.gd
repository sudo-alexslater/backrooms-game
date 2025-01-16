extends Node3D
class_name Level0Cell

enum WallType {
	north,
	south,
	east, 
	west
}

@export var wall_type: WallType :
	set(new_type):
		wall_type = new_type
		wall_type_updated()

func _ready() -> void:
	wall_type_updated()

func wall_type_updated():
	$Cube.position = Vector3(0, 0, 0)
	$Cube.rotation = Vector3(0, 0, 0)
	if wall_type == WallType.north:
		# rotate 90
		$Cube.rotate_y(deg_to_rad(90.0))
		# move back by 2
		$Cube.translate(Vector3(2, 0, 0))
	if wall_type == WallType.south:
		# rotate 90
		$Cube.rotate_y(deg_to_rad(90.0))
		# move forward by 2
		$Cube.translate(Vector3(-2, 0, 0))
	if wall_type == WallType.east:
		# move right by 2
		$Cube.translate(Vector3(2, 0, 0))
	if wall_type == WallType.west:
		# move left by 2
		$Cube.translate(Vector3(-2, 0, 0))

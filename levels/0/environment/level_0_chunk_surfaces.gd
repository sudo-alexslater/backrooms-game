extends Object
## Floor + ceiling for one procedural chunk; visuals match level_0_main Floor/Ceiling materials.

const TEX_CEILING := preload("res://resources/textures/environment/ceiling.jpg")
const TEX_CARPET := preload("res://resources/textures/environment/carpet.jpg")

const CEILING_Y := 4.0
const FLOOR_ALBEDO := Color(0.42068434, 0.42068434, 0.42068434, 1)


static func _add_floor(root: Node3D, cx: float, cz: float, w: float) -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = FLOOR_ALBEDO
	floor_mat.albedo_texture = TEX_CARPET
	floor_mat.uv1_triplanar = true
	floor_mat.uv1_world_triplanar = true

	var plane := PlaneMesh.new()
	plane.size = Vector2(w, w)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = plane
	floor_mesh.material_override = floor_mat
	floor_mesh.position = Vector3(cx, 0.0, cz)
	root.add_child(floor_mesh)

	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(cx, -0.25, cz)
	var floor_col := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(w, 0.5, w)
	floor_col.shape = floor_box
	floor_body.add_child(floor_col)
	root.add_child(floor_body)


## Small floor under a spawn point (no ceiling) until procedural chunks stream in.
static func build_spawn_floor_pad(world_center_xz: Vector2, half_extent_xz: float) -> Node3D:
	var root := Node3D.new()
	var w := half_extent_xz * 2.0
	_add_floor(root, world_center_xz.x, world_center_xz.y, w)
	return root


static func build(world_center_xz: Vector2, world_half_extent_xz: float) -> Node3D:
	var root := Node3D.new()
	var cx := world_center_xz.x
	var cz := world_center_xz.y
	var w := world_half_extent_xz * 2.0

	_add_floor(root, cx, cz, w)

	var ceil_mat := StandardMaterial3D.new()
	ceil_mat.albedo_texture = TEX_CEILING
	ceil_mat.albedo_texture_force_srgb = true
	ceil_mat.uv1_triplanar = true
	ceil_mat.uv1_world_triplanar = true

	var plane := PlaneMesh.new()
	plane.size = Vector2(w, w)

	var ceil_mesh := MeshInstance3D.new()
	ceil_mesh.mesh = plane
	ceil_mesh.material_override = ceil_mat
	ceil_mesh.position = Vector3(cx, CEILING_Y, cz)
	ceil_mesh.rotation.x = PI
	root.add_child(ceil_mesh)

	var ceil_body := StaticBody3D.new()
	ceil_body.position = Vector3(cx, CEILING_Y, cz)
	var ceil_col := CollisionShape3D.new()
	var ceil_box := BoxShape3D.new()
	ceil_box.size = Vector3(w, 0.5, w)
	ceil_col.shape = ceil_box
	ceil_body.add_child(ceil_col)
	root.add_child(ceil_body)

	return root

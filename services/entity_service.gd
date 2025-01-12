extends Node

# ------------------------------
# GLOBAL ENTITY SYSTEM
# ------------------------------
var entities: Dictionary = {}
@rpc("call_local", "any_peer")
func get_entity(guid: String) -> EntityState:
	if entities.has(guid):
		return entities[guid]
	else:
		return EntityState.new()
@rpc("call_local", "any_peer")
func spawn_entity(node_path: String, position: Vector2, options: Dictionary):
	var node = (load(node_path) as PackedScene).instantiate()
	node.init(options)
	node.position = position
	get_node("/root/game").add_child(node)
	
@rpc("call_local", "any_peer")
func add_entity(guid: String, state: EntityState): 
	# update global dict
	entities[guid] = state
	# spawn entity
	var entity_instance = state.node.instantiate()
	entity_instance.position = state.initial_position
	get_node("/root/game").add_child(entity_instance)
@rpc("call_local", "any_peer")
func update_entity(guid: String, new_state: EntityState):
	entities[guid] = new_state
@rpc("call_local", "any_peer")
func remove_entity(guid: String): 
	entities.erase(guid)

# ------------------------------
# SPAWN POINTS 
# ------------------------------
var spawn_points: Array[SpawnPoint] = []
func register_spawnpoint(spawn_point: SpawnPoint):
	spawn_points.push_back(spawn_point)
func deregister_spawnpoint(spawn_point: SpawnPoint):
	spawn_points.erase(spawn_point)
func get_random_spawnpoint():
	var spawn_points_node = get_node("/root/game/SpawnPoints")
	if !spawn_points_node.is_node_ready():
		await spawn_points_node.ready
	if spawn_points.size() == 0:
		return null
	return spawn_points.pick_random()

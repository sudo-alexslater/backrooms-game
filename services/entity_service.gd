extends Node

# ------------------------------
# GLOBAL ENTITY SYSTEM
# ------------------------------
var entities: Dictionary = {}
func get_entities_serialised() -> Array[Dictionary]:
	var entities_as_dict = []
	for entity in entities.values():
		entities_as_dict.push_back(entity.to_dict())
	return entities_as_dict
func get_entity(guid: String) -> EntityState:
	if entities.has(guid):
		return entities[guid]
	else:
		return EntityState.new()
func spawn_entity(state: EntityState):
	var new_node := state.node.instantiate()
	new_node.position = state.initial_position
	new_node.name = state.guid
	get_node("/root/game").add_child(new_node)
@rpc("call_local", "authority")
func update_entity_list(new_entities: Array[Dictionary]):
	var old_entities = entities
	var refreshed_entities = {}
	for new_entity_dict in new_entities:
		var new_entity = EntityState.new(new_entity_dict)
		refreshed_entities[new_entity.guid] = new_entity
		
		# spawn if new entity
		var existing_node = get_node_or_null("/root/game/" + new_entity.guid)
		if !existing_node:
			spawn_entity(new_entity)
@rpc("call_remote", "any_peer")
func fetch_entity_list():
	update_entity_list.rpc(get_entities_serialised())
@rpc("call_local", "any_peer")
func add_entity(state_dict: Dictionary): 
	if !multiplayer.is_server():
		Logger.error("Non server attempted to add entity")
		return
	var state = EntityState.new(state_dict)
	# update global dict
	entities[state.guid] = state
	update_entity_list.rpc(get_entities_serialised())
@rpc("call_local", "any_peer")
func remove_entity(guid: String): 
	if !multiplayer.is_server():
		Logger.error("Non server attempted to remove entity")
		return
	entities.erase(guid)
	update_entity_list.rpc(get_entities_serialised())

# ------------------------------
# SPAWN POINTS 
# ------------------------------
func get_random_spawnpoint() -> Vector3:
	var randx := randf() * 10
	var randz := randf() * 10
	
	return Vector3(randx, 1, randz)

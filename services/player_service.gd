extends Node

signal local_player_state_changed(state)

@export var local_player_name := "Local Player" : 
	set(input):
		local_player_state.name = input
		local_player_name = input
		send_local_player_state()

var player := preload("res://entities/player/player.tscn");

func _ready():
	NetworkService.connected_to_game.connect(send_local_player_state)

var local_player_state: PlayerState :
	set(input):
		local_player_state = input
		local_player_state_changed.emit(input)
	get:
		if local_player_state == null:
			local_player_state = PlayerState.new({"name": local_player_name, "id": multiplayer.get_unique_id()})
		return local_player_state
var pending_send_local_player_state := false
func send_local_player_state():
	if not NetworkService.is_connected_to_game:
		if pending_send_local_player_state:
			return
		await NetworkService.connected_to_game
	if is_multiplayer_authority():
		set_player_state(local_player_state.to_dict())
	else:
		set_player_state.rpc_id(1, local_player_state.to_dict())

var player_states: Dictionary = {}
func get_player_state_or_null(id: int) -> PlayerState:
	var has_info = player_states.has(id)
	if has_info:
		return player_states[id] 
	else:
		return null
func serialise_player_states(input):
	var new_states = {}
	for id in input:
		new_states[id] = input[id].to_dict()
	return new_states
func deserialise_player_states(input):
	var new_states = {}
	for id in input:
		new_states[id] = PlayerState.new(input[id])
	return new_states

func get_player_node_or_null(id):
	return get_node_or_null("/root/game/" + str(id))
func spawn_player(id: int, state: PlayerState):
	if not NetworkService.is_connected_to_game:
		await NetworkService.connected_to_game

	var existing_player = get_player_node_or_null(id)
	if existing_player != null:
		return
		
	var game_root = get_node("/root/game")
	var instance: Player = player.instantiate()
	instance.is_local_player = id == multiplayer.get_unique_id()
	instance.state = state
	instance.name = str(id);
	game_root.add_child(instance);
	Logger.debug("Player " + str(id) + " has spawned.")
func despawn_player(id):
	var to_despawn = get_player_node_or_null(id)
	if to_despawn != null:
		to_despawn.queue_free()

# ==================
# RPCs
# ==================
@rpc("call_local", "authority")
func update_player_states(new_states_input):
	var old_states = player_states.duplicate()
	var new_states = deserialise_player_states(new_states_input)
	
	# setup map data structure
	var all_states = {}
	for id in old_states:
		all_states[id] = {"old": old_states[id], "new": false}
	for id in new_states:
		if !all_states.has(id):
			all_states[id] = {"old": false}
		all_states[id]["new"] = new_states[id]
		
	var local_player_id := multiplayer.get_unique_id()
	Logger.debug("Processing states: " + str(all_states))
	for id in all_states:
		var states = all_states[id]
		var old_state = states["old"]
		var new_state = states["new"]
		var player_is_spawned = get_player_node_or_null(id) != null
		
		# notify if local player state change
		if id == local_player_id:
			local_player_state = new_state
		# on player disconnected
		if player_is_spawned and !new_state:
			await despawn_player(id)
		# on new player
		if !player_is_spawned and new_state:
			await spawn_player(id, new_state)
	
	# update player states dict
	player_states = new_states

@rpc("any_peer")
func set_player_state(input):
	# this function may possibly be called directly
	var id = 1
	if multiplayer.get_remote_sender_id() != 0:
		id = multiplayer.get_remote_sender_id()
	# serialise and send new states
	var new_states = player_states.duplicate()
	var player_info = PlayerState.new(input)
	new_states[id] = player_info
	var states_to_send = serialise_player_states(new_states)
	update_player_states.rpc(states_to_send)

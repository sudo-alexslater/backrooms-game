extends Node

var is_connected_to_game := false :
	set(input):
		is_connected_to_game = input
		if input == true:
			connected_to_game.emit()
	get:
		return is_connected_to_game
signal connected_to_game

var peer = ENetMultiplayerPeer.new()
var url = "127.0.0.1"
const port = 9009

func load_map():
	# less delay with change to packed
	get_tree().change_scene_to_packed(load('res://levels/0/level_0_main.tscn'))
	# short await to allow scene to fully change
	await get_tree().create_timer(0.2).timeout
	if not is_authority():
		ItemService.fetch_network_items.rpc_id(1)
		EntityService.fetch_entity_list.rpc_id(1)
func host_server():
	# initialize multiplayer connection
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	GameLogger.debug("Server started on port " + str(port))
	await load_map()
	is_connected_to_game = true
func disconnect_client():
	GameLogger.debug("Disconnecting..")
	peer.close()
	is_connected_to_game = false
func connect_client():
	GameLogger.debug("Connecting..")
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_server_connected)
	# initialize multiplayer connection
	peer.create_client(url, port)
	multiplayer.multiplayer_peer = peer
	
func _on_server_connected() -> void:
	GameLogger.debug("Server connected")
	await load_map()
	is_connected_to_game = true
func _on_server_disconnected() -> void:
	peer.close()
	is_connected_to_game = false
	GameLogger.debug("Server disconnected")
	
func is_authority():
	var id = multiplayer.get_unique_id()
	return id == 1 or id == 0

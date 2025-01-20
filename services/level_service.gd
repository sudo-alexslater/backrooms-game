extends Node

var player: CharacterBody3D
var maze: Node2D
var wall := preload("res://levels/0/environment/level_0_cell.tscn")

# Called once per tick
func _process(_delta):
	# locate player and maze
	if !player:
		var current_player: CharacterBody3D = get_node_or_null("/root/game/" + str(multiplayer.get_unique_id()))
		if current_player:
			player = current_player
	
	if !player:
		return
	render_chunks()

# ==================
# Chunk Generation
# ==================
var chunk_size := 25
var room_size := 20
var tile_size := 4
var view_distance := 1
var num_of_wall_breaks := 2
var chunk_data := {}
var is_loaded := {}
var is_loading := {}

# --- util ---
func get_cell_id(x: int, y: int):
	return str(x) + "/" + str(y)
func get_blank_region() -> Dictionary:
	var out := {}
	for x in chunk_size:
		for y in chunk_size:
			out[get_cell_id(x, y)] = {
				"x": x,
				"y": y,
				"region": "none",
				"is_wall": false,
				"is_loot_tile": false
			}
	return out
func spawn_loot(at: Vector3):
	EntityService.add_entity({
		"guid": IDService.v4(),
		"initial_position": at,
		"node_path": "res://entities/inventories/filing_cabinet.tscn"
	})

# --- chunks ---
# locate the player position and render the chunks in view distance
func render_chunks():
	var player_pos: Vector3 = floor(player.global_position / tile_size)
	var player_chunk_pos: Vector3 = floor(player_pos / chunk_size) * chunk_size
	
	var chunk_id = get_cell_id(player_chunk_pos.x, player_chunk_pos.z)
	if !is_loaded.has(chunk_id) and !is_loading.has(chunk_id):
		request_chunk.rpc_id(1, player_chunk_pos.x, player_chunk_pos.z)
		is_loading[chunk_id] = true

# load chunk on server
@rpc("any_peer", "call_local")
func request_chunk(x: int, y: int):
	if !multiplayer.is_server():
		return
	if chunk_data.has(get_cell_id(x, y)):
		load_chunk.rpc(x, y, chunk_data[get_cell_id(x, y)])
		return
	else: 
		# get new chunk data
		var new_chunk = [] 
		await blobby_divide_region(new_chunk, get_blank_region(), x, y)
		# establish one loot tile
		new_chunk.pick_random().is_loot_tile = true
		# store chunk data
		chunk_data[get_cell_id(x, y)] = new_chunk
		# communicate chunk to network
		load_chunk.rpc_id(multiplayer.get_remote_sender_id(), x, y, new_chunk)

# receive load chunk instruction from server
@rpc("authority", "call_local")
func load_chunk(x: int, y: int, chunk_data: Array):
	var chunk_id = get_cell_id(x, y)
	# todo: add chunk as node3d to organize walls
	
	for cell in chunk_data:
		# one cell is 2x2
		var pos_x = x*tile_size + tile_size*cell.x
		var pos_y = y*tile_size + tile_size*cell.y
		if cell.north_wall:
			var wall_node: Level0Cell = wall.instantiate()
			wall_node.position = Vector3(pos_x, 0, pos_y)
			wall_node.wall_type = 0
			get_node("/root/game/Map").add_child(wall_node)
		if cell.south_wall:
			var wall_node: Level0Cell = wall.instantiate()
			wall_node.position = Vector3(pos_x, 0, pos_y)
			wall_node.wall_type = 1
			get_node("/root/game/Map").add_child(wall_node)
		if cell.east_wall:
			var wall_node: Level0Cell = wall.instantiate()
			wall_node.position = Vector3(pos_x, 0, pos_y)
			wall_node.wall_type = 2
			get_node("/root/game/Map").add_child(wall_node)
		if cell.west_wall:
			var wall_node: Level0Cell = wall.instantiate()
			wall_node.position = Vector3(pos_x, 0, pos_y)
			wall_node.wall_type = 3
			get_node("/root/game/Map").add_child(wall_node)
		if cell.is_loot_tile:
			spawn_loot(Vector3(pos_x, 0, pos_y))
	# set loading flags
	is_loaded[chunk_id] = true
	is_loading[chunk_id] = false
func unload_chunk(x: int, y: int):
	pass

# --- maze generation techniques ---
# recursive division function mutating a map
func blobby_divide_region(chunk_data: Array, in_region: Dictionary = get_blank_region(), x =0, y=0):
	# exit if room size met
	if in_region.values().size() <= room_size:
		return
		
	# pick two random cells keys to be the two region seeds
	var region = in_region.duplicate(true)
	var options = region.keys()
	var a_seed_key = options.pick_random()
	var a_seed = region[a_seed_key]
	a_seed.region = "a"
	options.erase(a_seed_key)
	var b_seed_key = options.pick_random()
	var b_seed = region[b_seed_key]
	b_seed.region = "b"	
	 
	# prime queue and start splitting regions
	var queue = [a_seed, b_seed]
	var processed = []
	var region_a = {}
	var region_b = {}
	
	while queue.size() > 0:
		# take random item from the queue
		var item = queue.pick_random()
		queue.erase(item)
		processed.push_back(item)
		
		# move item into respective region
		var copied_item = item.duplicate(true)
		copied_item.region = "none"
		if item.region == "a":
			region_a[get_cell_id(item.x, item.y)] = copied_item
		else:
			region_b[get_cell_id(item.x, item.y)] = copied_item
		
		# get neighbors
		var above = region.get(get_cell_id(item.x, item.y - 1), false)
		var below = region.get(get_cell_id(item.x, item.y + 1), false)
		var left = region.get(get_cell_id(item.x - 1, item.y), false)
		var right = region.get(get_cell_id(item.x + 1, item.y), false)
		var neighbors = [above, below, left, right]
		
		# spread region to neighbors
		for neighbor in neighbors:
			# only neighbors without a region
			if !neighbor or neighbor.region != "none":
				continue
			neighbor.region = item.region
			if !queue.has(neighbor) && !processed.has(neighbor):
				queue.push_back(neighbor)
	
	# create walls between generated regions
	var new_walls = []
	for item in region_a.values():
		var north = 1 if region_b.get(get_cell_id(item.x, item.y - 1), false) else 0
		var east = 1 if region_b.get(get_cell_id(item.x + 1, item.y), false) else 0
		var south = 1 if region_b.get(get_cell_id(item.x, item.y + 1), false) else 0
		var west = 1 if region_b.get(get_cell_id(item.x - 1, item.y), false) else 0
		#print("N", north, "S", south, "W", west, "E", east)
		item.north_wall = north
		item.east_wall = east
		item.south_wall = south
		item.west_wall = west
		
		if north + east + south + west > 0:
			new_walls.push_back(item)
	
	# apply wall breaks
	for i in num_of_wall_breaks:
		if new_walls.size() >= 1:
			var selected_wall = new_walls.pick_random()
			new_walls.erase(selected_wall)
	
	# mutate chunk data with new walls
	chunk_data.append_array(new_walls)

	# divide further
	await blobby_divide_region(chunk_data, region_a, x, y)
	await blobby_divide_region(chunk_data, region_b, x, y)

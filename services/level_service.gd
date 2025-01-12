extends Node

var player: CharacterBody2D
var maze: Node2D
var lootbox := preload("res://items/loot_box/loot_box.tscn")

# Called once per tick
func _process(_delta):
	# locate player and maze
	if !player or !maze:
		var current_maze: TileMap = get_node_or_null("/root/game/Maze")
		var current_player: CharacterBody2D = get_node_or_null("/root/game/" + str(multiplayer.get_unique_id()))
		if current_maze:
			maze = current_maze
		if current_player:
			player = current_player
	
	if !maze or !player:
		return
	render_chunks()

# ==================
# Chunk Generation
# ==================
var chunk_size := 20
var room_size := 50
var tile_size := 32
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
func spawn_loot(at: Vector2):
	EntityService.spawn_entity("res://items/loot_box/loot_box.tscn", at, {})

# --- chunks ---
# locate the player position and render the chunks in view distance
func render_chunks():
	var player_pos: Vector2 = floor(maze.to_local(player.global_position) / tile_size)
	var player_chunk_pos: Vector2 = floor(player_pos / chunk_size) * chunk_size

	# load chunks if not loaded
	var view_distance_start = Vector2(player_chunk_pos.x - (view_distance * chunk_size / 2), player_chunk_pos.y - (view_distance * chunk_size / 2))
	for x in view_distance:
		for y in view_distance:
			var cell_id = get_cell_id(x, y)
			if !is_loaded.has(cell_id) and !is_loading.has(cell_id):
				var load_x = view_distance_start.x + (x*chunk_size);
				var load_y = view_distance_start.y + (y*chunk_size);
				request_chunk.rpc_id(1, load_x, load_y)
				is_loading[cell_id] = true
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
		blobby_divide_region(new_chunk)
		# establish one loot tile
		new_chunk.pick_random().is_loot_tile = true
		# store chunk data
		chunk_data[get_cell_id(x, y)] = new_chunk
		# communicate chunk to network
		load_chunk.rpc_id(multiplayer.get_remote_sender_id(), x, y, new_chunk)

# receive load chunk instruction from server
@rpc("authority", "call_local")
func load_chunk(x: int, y: int, chunk_data: Array):
	var cell_id = get_cell_id(x, y)

	var mapped_chunk = {}
	for cell in chunk_data:
		var shifted_x = (cell.x * 2) + 1
		var shifted_y = (cell.y * 2) + 1
		mapped_chunk[get_cell_id(shifted_x, shifted_y)] = {"x": shifted_x, "y": shifted_y, "type": "empty"}
		if cell.north_wall:
			mapped_chunk[get_cell_id(shifted_x, shifted_y + 1)] = {"x": shifted_x, "y": shifted_y + 1, "type": "wall"}
		if cell.south_wall:
			mapped_chunk[get_cell_id(shifted_x, shifted_y - 1)] = {"x": shifted_x, "y": shifted_y - 1, "type": "wall"}
		if cell.east_wall:
			mapped_chunk[get_cell_id(shifted_x + 1, shifted_y)] = {"x": shifted_x + 1, "y": shifted_y, "type": "wall"}
		if cell.west_wall:
			mapped_chunk[get_cell_id(shifted_x - 1, shifted_y)] = {"x": shifted_x - 1, "y": shifted_y, "type": "wall"}
			
	for index_x in range(0, (chunk_size*2) + 1):
		var row = ""
		for index_y in range(0, (chunk_size*2) + 1):
			var this_cell = get_cell_id(index_x, index_y)

			if mapped_chunk.has(this_cell):
				if mapped_chunk[this_cell].type == "wall":
					row += "*"
				else:
					row += " "
			else: 
				row += " "
		print(row)
	
	for cell_key in mapped_chunk:
		var cell = mapped_chunk[cell_key]
		var cell_x = cell.x + x
		var cell_y = cell.y + y
		var cell_coords = Vector2(cell_x, cell_y)
		
		if cell.type == "wall":
			maze.set_cell(0, cell_coords, 1, Vector2(1, 1))
			
		#if cell.is_loot_tile:
			#spawn_loot(maze.to_global(maze.map_to_local(cell_coords)))

	# set loading flags
	is_loaded[cell_id] = true
	is_loading[cell_id] = false
func unload_chunk(x: int, y: int):
	pass

# --- maze generation techniques ---
# recursive division function mutating a map
func blobby_divide_region(chunk_data: Array, in_region: Dictionary = get_blank_region()):
	# exit if room size met
	if in_region.values().size() <= room_size:
		return
		
	var region = in_region.duplicate(true)
	# pick two random cells keys to be the two region seeds
	var options = region.keys()
	var a_seed_key = options.pick_random()
	var b_seed_key = options.pick_random()
	while a_seed_key == b_seed_key:
		b_seed_key = options.pick_random()

	# get seeds and set their regions
	var a_seed = region[a_seed_key]
	a_seed.region = "a"
	var b_seed = region[b_seed_key]
	b_seed.region = "b"
	 
	# prime the queue 
	var queue = [a_seed, b_seed]
	var region_a = {}
	var region_b = {}
	
	# assign regions
	while queue.size() > 0:
		# take random item from the queue
		var item = queue.pick_random().duplicate(true)
		queue.erase(item)
		
		# move item into respective region
		if item.region == "a":
			var new_item = item.duplicate()
			new_item.region = "none"
			region_a[get_cell_id(new_item.x, new_item.y)] = new_item
		else:
			var new_item = item.duplicate()
			new_item.region = "none"
			region_b[get_cell_id(new_item.x, new_item.y)] = new_item
		
		# get neighbors
		var above = region.get(get_cell_id(item.x, item.y - 1), false)
		var below = region.get(get_cell_id(item.x, item.y + 1), false)
		var left = region.get(get_cell_id(item.x - 1, item.y), false)
		var right = region.get(get_cell_id(item.x + 1, item.y), false)
		var neighbors = [above, below, left, right]
		
		# spread region to neighbors
		for neighbor in neighbors:
			if !neighbor or neighbor.region != "none":
				continue
			neighbor.region = item.region
			if !queue.has(neighbor) && !region_a.has(get_cell_id(neighbor.x, neighbor.y)) && !region_b.has(get_cell_id(neighbor.x, neighbor.y)):
				queue.push_back(neighbor)
	
	# create walls between regions
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
		
		if north | east | south | west > 0:
			chunk_data.push_back(item)
	
	# apply wall breaks
	if chunk_data.size() > 1:
		for i in num_of_wall_breaks:
			chunk_data.erase(chunk_data.pick_random())
	
	# divide further
	await blobby_divide_region(chunk_data, region_a)
	await blobby_divide_region(chunk_data, region_b)

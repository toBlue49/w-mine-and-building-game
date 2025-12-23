extends GridMap

var size := -1
const chunk_size := 8
var chunk_updates: int = 0
var get_level_array = []
var get_level_array_slice = 0
var gotten_y = []
var block_nodes = [
	preload("res://scenes/blocks/omni_light_light_block.tscn"),
	preload("res://scenes/blocks/sand_object.tscn")
]
@onready var chunks: Node3D = $"../Chunks"
@onready var world: Node3D = $".."
@onready var player: CharacterBody3D
@onready var objects: Node3D = $"../Objects"
@onready var border: Node3D = $"../Border"
@onready var chat: Control = $"../CanvasLayer/Chat"

@export_range(4, 256, 4) var resolution = 16:
	set(new_resolution):
		resolution = new_resolution
@export var noise: FastNoiseLite
@export var rand_noise: FastNoiseLite
@export_range(1.0, 128.0, 1.0) var height = 64:
	set(new_hight):
		height = new_hight
@export var y_offset: int = 32

##Generation:

func get_rand_noise(x:int, y:int) -> int:
	return floori(rand_noise.get_noise_2d(x, y) * 1000)

func get_height(x: int, y: int) -> int:
	var ball = noise.get_noise_2d(x, y) * height
	return ball

func update_gridmap():
	for x in size:
		for z in size:
			if gotten_y.find(str("x", x, "z", z)) >= 0:
				print_rich("[color=yellow][WARNING] Tried to get height twice: [b][/color]", str("x", x, "z", z))
				return
			gotten_y.append(str("x", x, "z", z))
			var y_level = get_height(x, z) + y_offset
			set_cell_item(Vector3i(x, y_level, z), 0)
			
			#fill ground
			for i in y_level-1:
				var j = i+1
				if get_cell_item(Vector3i(x, y_level-j, z)) != 0:
					set_cell_item(Vector3i(x, y_level-j, z), 1)
					
			#fill dirt layer
			for i in 3:
				set_cell_item(Vector3i(x, y_level-i-1, z), 2)
	gotten_y.clear()

func render_gridmap():
	@warning_ignore("integer_division")
	for xpos in size/chunk_size:
		@warning_ignore("integer_division")
		for zpos in size/chunk_size:
			update_single_chunk(chunks.get_node("x" + str(xpos) + "z" + str(zpos)), xpos, zpos, Vector3i(0, 0, 0))

func render_chunk(gridmap, x, z):
	@warning_ignore("integer_division")
	if x >= size/chunk_size or z >= size/chunk_size or x < 0 or z < 0:
		return
	for y in 128:
		for lx in chunk_size:
			for lz in chunk_size:
				var i = Vector3i(lx+chunk_size*x, y, lz+chunk_size*z)
				if get_cell_item(i + Vector3i(0, 1, 0)) == -1 or get_cell_item(i + Vector3i(0, -1, 0)) == -1 or get_cell_item(i + Vector3i(1, 0, 0)) == -1 or get_cell_item(i + Vector3i(-1, 0, 0)) == -1 or get_cell_item(i + Vector3i(0, 0, 1)) == -1 or get_cell_item(i + Vector3i(0, 0, -1)) == -1:
					#if air
					gridmap.set_cell_item(Vector3i(i.x%chunk_size, i.y, i.z%chunk_size), get_cell_item(i))
				elif get_cell_item(i + Vector3i(0, 1, 0)) == 3 or get_cell_item(i + Vector3i(0, -1, 0)) == 3 or get_cell_item(i + Vector3i(1, 0, 0)) == 3 or get_cell_item(i + Vector3i(-1, 0, 0)) == 3 or get_cell_item(i + Vector3i(0, 0, 1)) == 3 or get_cell_item(i + Vector3i(0, 0, -1)) == 3:
					#if leaves
					gridmap.set_cell_item(Vector3i(i.x%chunk_size, i.y, i.z%chunk_size), get_cell_item(i))

func update_single_chunk(gridmap: GridMap, x , z, global_map_pos):
	var map_pos = global_map_pos%chunk_size

	render_chunk(gridmap, x, z)

	#update neighbor chunks
	if map_pos.x == 0 and x > 0:
		render_chunk(chunks.get_node(str("x", x-1, "z", z)), x-1, z)
	@warning_ignore("integer_division")
	if map_pos.x == chunk_size-1 and x < size/chunk_size-1:
		render_chunk(chunks.get_node(str("x", x+1, "z", z)), x+1, z)
	if map_pos.z == 0 and z > 0:
		render_chunk(chunks.get_node(str("x", x, "z", z-1)), x, z-1)
	@warning_ignore("integer_division")
	if map_pos.z == chunk_size-1 and z < size/chunk_size-1:
		render_chunk(chunks.get_node(str("x", x, "z", z+1)), x, z+1)
	
	chunk_updates += 1

func create_gridmap_chunks(do_delete = false):
	if do_delete:
		for i in chunks.get_children():
			i.free()
		
	@warning_ignore("integer_division")
	for i in size/chunk_size:
		@warning_ignore("integer_division")
		for j in size/chunk_size:
			var scene = load("res://scenes/grid_map_render.tscn")
			var node = scene.instantiate()
			node.position = Vector3(i*chunk_size*2, 0, j*chunk_size*2)
			node.name = str("x", i, "z", j)
			chunks.add_child(node)

func move_player(peer_id = 0):
	for i in world.get_children():
		if i is CharacterBody3D and peer_id == 0:
			i.queue_free()
	@warning_ignore("integer_division")
	var half_size = size/2
	var pos = Vector3(size, 0, size)
	pos.y = abs(get_height(half_size, half_size)) * 2 + y_offset*2 +2
	print_rich("[INFO] Player Y Position: [b]" + str(pos.y))
	world.add_player(peer_id, pos)

func generate_features():
	for x in size:
		for z in size:
			if get_rand_noise(x, z) >= 975: #Trees
				place_tree(x, get_height(x, z) + y_offset, z)

func place_tree(x, y, z):
	var tree_height:int
	if get_rand_noise(x, z+100) >= 800:
		tree_height = 4
	else:
		tree_height = 5
	
	for y_leaves in 3:
		for x_leaves in 3:
			for z_leaves in 3:
				set_cell_item(Vector3i(x+(x_leaves-1), y+y_leaves+tree_height-1, z+(z_leaves-1)), 4)

	for i in tree_height:
		set_cell_item(Vector3i(x, y+i+1, z), 3)

func match_border_to_size():
	border.get_node("movable").position.z = size*2+256
	border.get_node("MeshInstance3Dmovable2").position.x = size*2+256

func GENERATE():
	#set rand_noise seed:
	rand_noise.seed = noise.seed
	
	print_rich("[INFO] [b]Generating Gridmap")
	update_gridmap()
	generate_features()
	create_gridmap_chunks()
	render_gridmap()
	match_border_to_size()
	await get_tree().process_frame
	print_rich("[color=green][SUCCESS] [b]Done!")

func init_singleplayer():
	if global.did_generate_level == false:
		noise.set_seed(randi_range(-2147483646, 2147483646))
		global.show_loading_screen(true, "Generating Level...")
		await get_tree().process_frame
		GENERATE()
		move_player()
		global.show_loading_screen(false)
		global.did_generate_level = true
	player = world.get_node("0")

func init_host():
	if global.did_generate_level == false:
		if FileAccess.file_exists("user://levels/server.tscn"):
			print_rich("[INFO] server.tscn level found! Loading.")
			load_level_from_file("server.tscn")
		else:
			print_rich("[color=yellow][WARNING] server.tscn level NOT found! Generating new level.")
			noise.set_seed(randi_range(-2147483646, 2147483646))
			global.show_loading_screen(true, "Generating Level...")
			await get_tree().process_frame
			GENERATE()
			move_player(multiplayer.get_unique_id())
			await get_tree().process_frame
			global.show_loading_screen(false)
			global.did_generate_level = true
		
	player = world.get_node(str(multiplayer.get_unique_id()))
	
	#Host Init
	multiplayer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(0.75).timeout
			init_join.rpc(new_peer_id, [], size)
	)
	multiplayer.peer_disconnected.connect(
		func(leave_peer_id):
			print_rich("[INFO] Peer Disconnected. ID: [b]" + str(leave_peer_id))
			if world.get_node_or_null(str(leave_peer_id)):
				world.get_node_or_null(str(leave_peer_id)).queue_free()
	)

@rpc("reliable")
func init_join(peer_id, level_array: Array, gridmap_size: int):
	size = gridmap_size
	@warning_ignore("integer_division")
	var half_size = size/2
	var pos = Vector3(half_size*2, 0, half_size*2)

	#Get GridMap
	for i in size:
		get_chunk.rpc(multiplayer.get_unique_id(), i)
		await get_tree().process_frame
		global.show_loading_screen(true, "Requesting Slice %s" % i)
		while get_level_array_slice != i:
			await get_tree().create_timer(0.01).timeout
	
	global.show_loading_screen(true, "Loading Level..")
	await get_tree().process_frame
	array_to_level(get_level_array)
	create_gridmap_chunks()
	render_gridmap()
	
	#Chat
	chat.add_message.rpc("serverplayer", "%s connected." % global.player_name)
	
	#Create Player
	print_rich("[INFO] Init Join Peer ID: [b]", peer_id)
	pos.y = abs(get_height(half_size, half_size)) * 2 + y_offset*2 +4
	print_rich("[INFO] Player Y Position: [b]" + str(pos.y))
	world.add_player_multiplayer.rpc(peer_id, Vector3(0, 4, 0))
	player = world.get_node(str(multiplayer.get_unique_id()))
	
	#Set Player Position
	player.position = pos
	
	#Border
	match_border_to_size()
	global.show_loading_screen(false)

func _ready():
	second_routine()

##At Runtime:

@rpc("any_peer", "call_remote")
func arrive_chunk(peer_get:int, result: Array, slice: int):
	if multiplayer.get_unique_id() == peer_get:
		for i in result:
			get_level_array.append(i)
		get_level_array_slice = slice

@rpc("any_peer", "call_remote")
func get_chunk(peer_get: int, slice: int):
	if multiplayer.get_unique_id() == 1:
		await get_tree().process_frame
		var result: Array = level_to_array(slice)
		arrive_chunk.rpc(peer_get, result, slice)

func second_routine():
	await get_tree().create_timer(1.0).timeout
	if player:
		player.update_chunk_updates(chunk_updates)
	chunk_updates = 0
	second_routine()

@rpc("call_local", "any_peer")
func destroy_block(world_coord):
	var map_pos = local_to_map(world_coord)
	var chunk = str("x", floor(map_pos.x/chunk_size), "z", floor(map_pos.z/chunk_size))
	var chunk_node = chunks.get_node(chunk)
	var block_id = get_cell_item(map_pos)

	#Handle Block Objects
	if block_id == 7 or block_id == 19:
		var object: Node3D = objects.get_node_or_null(str(map_pos) + "b" + str(get_cell_item(map_pos)))
		if object:
			object.queue_free()
	
	set_cell_item(map_pos, -1)
	update_single_chunk(chunk_node, floor(map_pos.x/chunk_size), floor(map_pos.z/chunk_size), map_pos)

	#Play Sound
	world.sound.play.rpc("block.break.default", world_coord, -2.0)

@rpc("call_local", "any_peer")
func place_block(world_coord, index):
	print_rich("[INFO] Placed Block index: [b]" + str(index))
	var map_pos = local_to_map(world_coord)
	var chunk = str("x", floor(map_pos.x/chunk_size), "z", floor(map_pos.z/chunk_size))
	var chunk_node = chunks.get_node(chunk)
	set_cell_item(map_pos, index)
	update_single_chunk(chunk_node, floor(map_pos.x/chunk_size), floor(map_pos.z/chunk_size), map_pos)

	#Handle Block Objects
	if index == 7:
		var omnilight: Node3D = block_nodes[0].instantiate()
		omnilight.position = map_to_local(map_pos)
		omnilight.name = str(map_pos) + "b7"
		objects.add_child(omnilight)
	if index == 19:
		var sand_object: Node3D = block_nodes[1].instantiate()
		sand_object.position = map_to_local(map_pos)
		sand_object.name = str(map_pos) + "b19"
		sand_object.init(map_pos, self)
		objects.add_child(sand_object)

	#Play Sound
	world.sound.play.rpc("block.place.default", world_coord, -2.0)

func level_to_array(slice: int) -> Array:
	var save_gridmap: GridMap = self
	var return_array: Array
	for i in save_gridmap.get_used_cells():
		if i.x == slice: return_array.append([i, get_cell_item(i)])
	return return_array

func array_to_level(array: Array):
	for cell in array:
		set_cell_item(cell[0], cell[1])

func save_level_to_file(path: String):
	var save_gridmap = GridMap.new()
	var save_objects = Node3D.new()
	save_gridmap = self
	save_objects = world.get_node("Objects")
	
	var scene = PackedScene.new()
	
	#set owner
	for i in objects.get_children():
		i.owner = objects
	
	#set_name
	save_gridmap.name = "GridMap_" + str(size)
	
	#Pack gridmap node
	scene.pack(save_gridmap)
	print_rich("[INFO] Saving following scene: [b]", scene)
	var result = scene.pack(save_gridmap)
	if result == OK:
		var error = ResourceSaver.save(scene, ("user://levels/" + path + ".tscn"))
		print_rich("[INFO] [color=yellow]Errorlevel Save Level Gridmap: " + str(error))
	
	#Pack Objects Node
	scene.pack(save_gridmap)
	print_rich("[INFO] Saving following scene: [b]", scene)
	var result_obj = scene.pack(save_objects)
	if result_obj == OK:
		var error = ResourceSaver.save(scene, ("user://levels/" + path + ".objects.tscn"))
		print_rich("[INFO] [color=yellow]Errorlevel Save Level Gridmap: " + str(error))

func load_level_from_file(file: String):
	global.show_loading_screen(true, "Loading Map...")
	await get_tree().process_frame
	var scene_gridmap = load("user://levels/" + file)
	var scene_objects = load("user://levels/" + file.trim_suffix(".tscn") + ".objects.tscn")
	var node_gridmap: GridMap = scene_gridmap.instantiate()
	var node_objects: Node3D
	if FileAccess.file_exists("user://levels/" + file.trim_suffix(".tscn") + ".objects.tscn"):
		node_objects = scene_objects.instantiate()
	else:
		print_rich("[WARNING] [color=yellow] No .object.tscn found. Loading default instead.")
		node_objects = Node3D.new()
	
	#get Saved GridMap Size
	var temp_size: int = node_gridmap.name.trim_prefix("GridMap_").to_int()
	print_rich("[INFO] Loaded GridMap temp_size: [b]" + str(temp_size))
	
	node_objects.name = "Objects"
	node_gridmap.name = "GridMap"
	
	#remove old
	name = "GridMapOld"
	world.get_node("Objects").queue_free()
	if world.get_node_or_null("0"):
		world.get_node_or_null("0").queue_free()
	
	#add nodes
	await get_tree().process_frame
	world.add_child(node_gridmap)
	if node_objects:
		world.add_child(node_objects)
	
	await get_tree().process_frame
	world.get_node("GridMap").size = temp_size 
	if global.is_multiplayer:
		world.get_node("GridMap").move_player(1)
	else:
		world.get_node("GridMap").move_player()
	world.get_node("GridMap").create_gridmap_chunks(true)
	world.get_node("GridMap").render_gridmap()
	world.get_node("GridMap").objects = world.get_node("Objects")
	world.get_node("GridMap").match_border_to_size()
	
	#Sand Block Fix 5000
	for node in world.get_node("GridMap").objects.get_children():
		if node.name.contains("b19"): #If is Sand
			var sand_pos = string_to_vector3(node.name.rstrip("b19"))
			node.free()
			
			#place new sand node
			var sand_object: Node3D = block_nodes[1].instantiate()
			sand_object.position = map_to_local(sand_pos)
			sand_object.name = str(sand_pos) + "b19"
			sand_object.init(sand_pos, world.get_node("GridMap"))
			world.get_node("GridMap").objects.add_child(sand_object)
	
	await get_tree().process_frame
	global.show_loading_screen(false)
	queue_free()

static func string_to_vector3(string := "") -> Vector3: #fun i found on the internet
	if string:
		var new_string: String = string
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array: Array = new_string.split(", ")
		prints(array, string)
	return Vector3.ZERO

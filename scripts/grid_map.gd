extends GridMap

var size := -1
const chunk_size := 8
var chunk_updates: int = 0
var get_level_array = []
var height_generated = {}
var protocol_version_diff = -32676
var block_nodes = [
	preload("res://scenes/blocks/omni_light_light_block.tscn"),
	preload("res://scenes/blocks/sand_object.tscn")
]
enum itmType{
	BLOCK, ITEM
}
var peer_id_name = {}
@onready var chunks: Node3D = $"../Chunks"
@onready var world: Node3D = $".."
@onready var player: CharacterBody3D
@onready var objects: Node3D = $"../Objects"
@onready var border: Node3D = $"../Border"
@onready var chat: Control = $"../UI/Chat"
@onready var entities: Node3D = $"../Entities"

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
	var ball = noise.get_noise_2d(x, y) * height + y_offset
	
	return ball

func update_gridmap():
	for x in size:
		for z in size:
			if height_generated.has(str("x", x, "z", z)) == true:
				print_rich("[color=yellow][WARNING] Tried to get height twice: [b][/color]", str("x", x, "z", z), " Returning...")
				return
			var y_level = get_height(x, z)
			height_generated.set(str("x", x, "z", z), y_level)
			set_cell_item(Vector3i(x, y_level, z), 0)
			
			#fill ground
			for i in y_level-1:
				var j = i+1
				if get_cell_item(Vector3i(x, y_level-j, z)) != 0:
					set_cell_item(Vector3i(x, y_level-j, z), 1)
					
			#fill dirt layer
			for i in 3:
				set_cell_item(Vector3i(x, y_level-i-1, z), 2)
		height_generated.clear()
		
func render_gridmap():
	@warning_ignore("integer_division")
	for xpos in size/chunk_size:
		@warning_ignore("integer_division")
		for zpos in size/chunk_size:
			update_single_chunk(chunks.get_node("x" + str(xpos) + "z" + str(zpos)), xpos, zpos, Vector3i(0, 0, 0))

func render_chunk(gridmap, x, z):
	@warning_ignore("integer_division")
	if x >= size/chunk_size or z >= size/chunk_size or x < 0 or z < 0: return
	if gridmap == null: return
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

func move_player(peer_id = 0): #singleplayer / hosting player
	for i in world.get_children():
		if i is CharacterBody3D and peer_id == 0:
			i.queue_free()
	@warning_ignore("integer_division")
	var pos = Vector3(size, 0, size)
	pos.y = get_height(pos.x/2, pos.z/2)*2
	print_rich("[INFO] Player Y Position: [b]" + str(pos.y))
	world.add_player(peer_id, pos)
	
	player = world.get_node(str(peer_id))
	
	#Move Player Up if in ground.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var counting_the_player_moving_ups = 0
	while player.get_slide_collision_count() > 0:
		counting_the_player_moving_ups += 1
		print_rich("[INFO] Player collision at spawn #%s! Moving up." % [counting_the_player_moving_ups])
		player.position.y += 2
		await get_tree().physics_frame

func generate_features():
	for x in size:
		for z in size:
			if get_rand_noise(x, z) >= 975: #Trees
				place_tree(x, get_height(x, z), z)

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

func spawn_test_entity(amount: int):
	for i in amount:
		var x = randi_range(0, size)
		var z = randi_range(0, size)
		var y = get_height(x, z) + 8
		
		var entity = world.TEST_ENTITY.instantiate()
		entity.init(Vector3(x*2, y*2, z*2))
		entities.add_child(entity, true)

func GENERATE():
	#set seed
	noise.set_seed(randi_range(-2147483646, 2147483646))
	rand_noise.seed = noise.seed
	
	#generation
	print_rich("[INFO] [b]Generating Gridmap")
	update_gridmap()
	generate_features()
	create_gridmap_chunks()
	render_gridmap()
	match_border_to_size()
	@warning_ignore("integer_division") spawn_test_entity(size/4) 
	await get_tree().process_frame
	print_rich("[color=green][SUCCESS] [b]Done!")

func init_singleplayer():
	if global.did_generate_level == false:
		global.show_loading_screen(true, "Generating Level...")
		await get_tree().process_frame
		GENERATE()
		await get_tree().process_frame
		move_player()
		global.did_generate_level = true
		global.show_loading_screen(false)

func init_host():
	if global.did_generate_level == false:
		if DirAccess.dir_exists_absolute("user://levels/server/"):
			print_rich("[INFO] server level found! Loading.")
			world.load_level_from_file("server")
			global.did_generate_level = true
		else:
			print_rich("[color=yellow][WARNING] server level NOT found! Generating new level.")
			global.show_loading_screen(true, "Generating Level...")
			await get_tree().process_frame
			GENERATE()
			move_player(multiplayer.get_unique_id())
			await get_tree().process_frame
			global.did_generate_level = true
			global.show_loading_screen(false)
		
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
				global.get_node("Scene/World/UI/Chat").add_message.rpc("serverplayer", "%s disconnected." % peer_id_name.get(leave_peer_id))
				world.get_node_or_null(str(leave_peer_id)).queue_free()
	)

@rpc("reliable")
func init_join(peer_id, _level_array: Array, gridmap_size: int):
	#Protocol Version Check
	protocol_version_diff = await global.request.get_var(1, self.get_path(), ["compare_protocol", global.PROTOCOL_VERSION])
	print_rich("[INFO] Protocol Difference: [b]%s" % protocol_version_diff)
	if protocol_version_diff != 0:
		if protocol_version_diff == -32676:
			global.show_popup("ServerError", "Connection Timeout")
		else:
			global.show_popup("ServerError", "Wrong Protocol Version.")
		return
	
	size = gridmap_size
	@warning_ignore("integer_division")
	var half_size = size/2
	var pos = Vector3(half_size, 0, half_size)

	#Get GridMap
	for i in size:
		global.show_loading_screen(true, "Requesting Slice %s" % i)
		get_level_array.append_array(await global.request.get_var(1, self.get_path(), ["get_block_slice", i]))
		if get_level_array[-1] is int: if get_level_array[-1] == -32676:
			global.show_popup("ServerError", "Connection Timeout")
			return
	
	global.show_loading_screen(true, "Loading Level...")
	await get_tree().process_frame
	
	#Render GridMap
	array_to_level(get_level_array)
	create_gridmap_chunks()
	render_gridmap()
	
	#Chat
	chat.add_message.rpc("serverplayer", "%s connected." % global.player_name)
	set_peer_id_name.rpc(multiplayer.get_unique_id(), global.player_name)
	
	#Create Player
	print_rich("[INFO] Init Join Peer ID: [b]", peer_id)
	pos.y = get_height(pos.x, pos.z)*2 + 8
	print_rich("[INFO] Player Y Position: [b]" + str(pos.y))
	world.add_player_multiplayer.rpc(peer_id, pos)
	player = world.get_node(str(multiplayer.get_unique_id()))
	
	#Border
	match_border_to_size()
	global.show_loading_screen(false)

func _ready():
	second_routine()

##At Runtime:

@rpc("any_peer", "call_remote")
func set_peer_id_name(id: int, player_name: String):
	if multiplayer.is_server():
		peer_id_name.set(id, player_name)

func second_routine():
	await get_tree().create_timer(1.0).timeout
	if player:
		player.update_chunk_updates(chunk_updates)
	chunk_updates = 0
	second_routine()

@rpc("call_local", "any_peer")
func destroy_block(world_coord, drop: bool):
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
	world.sound.play("block.break.default", world_coord, -2.0)
	
	#Drop Item
	if drop:
		var dropped_item = load("res://scenes/entity/dropped_item.tscn").instantiate()
		dropped_item.position = map_to_local(map_pos)
		dropped_item.name = str(map_pos) #NOTE: May be temporary
		entities.add_child(dropped_item)
		dropped_item.set_item([block_id, itmType.BLOCK])

@rpc("call_local", "any_peer")
func place_block(world_coord, index):
	var map_pos = local_to_map(world_coord)
	var chunk = str("x", floor(map_pos.x/chunk_size), "z", floor(map_pos.z/chunk_size))
	var chunk_node = chunks.get_node(chunk)
	set_cell_item(map_pos, index)
	update_single_chunk(chunk_node, floor(map_pos.x/chunk_size), floor(map_pos.z/chunk_size), map_pos)
	
	#Handle Block Objects
	place_block_object(map_pos, index)
	
	#Play Sound
	world.sound.play("block.place.default", world_coord, -2.0)

func place_block_object(map_pos, index):
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

func level_to_array(slice: int) -> Array:
	var save_gridmap: GridMap = self
	var return_array: Array
	for i in save_gridmap.get_used_cells():
		if i.x == slice:
			return_array.append([i, get_cell_item(i)])
			
			#Handle Objects
			if get_cell_item(i) == 7 or get_cell_item(i) == 19:
				return_array.append(["OBJECT", i , get_cell_item(i)])
	
	return return_array

func array_to_level(array: Array):
	for cell in array:
		if cell[0] is String: #Objects
			place_block_object(cell[1], cell[2])
		else: #Cells
			set_cell_item(cell[0], cell[1])

func LEGACY_load_level_from_file(file: String):
	global.show_loading_screen(true, "Loading Map...")
	await get_tree().process_frame
	var scene_gridmap = load("user://levels/" + file)
	if scene_gridmap == null:
		global.show_popup("LoadError", "Couldn't load level.")
		return
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
	
	#Update world variables
	world.grid_map = world.get_node("GridMap")
	world.objects = world.get_node("Objects")

	global.show_loading_screen(false)
	queue_free()

static func string_to_vector3(string := "") -> Vector3: #fun i found on the internet
	if string:
		var new_string: String = string
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array: Array = new_string.split(", ")
		var vector: Vector3 = Vector3(int(array[0]), int(array[1]), int(array[2]))

		return vector
	else:
		return Vector3.ZERO

extends GridMap

const size := 176
const chunk_size := 8
var gotten_y = []
@onready var chunks: Node3D = $"../Chunks"
@onready var player: CharacterBody3D = $"../Player"

@export_range(4, 256, 4) var resolution = 16:
	set(new_resolution):
		resolution = new_resolution
		update_gridmap()
@export var noise: FastNoiseLite
@export var rand_noise: FastNoiseLite
@export_range(1.0, 128.0, 1.0) var height = 64:
	set(new_hight):
		height = new_hight
@export var y_offset = 32

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
				print("tried to get noise twice: ", str("x", x, "z", z))
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

func create_gridmap_chunks():
	@warning_ignore("integer_division")
	for i in size/chunk_size:
		@warning_ignore("integer_division")
		for j in size/chunk_size:
			var scene = load("res://scenes/grid_map_render.tscn")
			var node = scene.instantiate()
			node.position = Vector3(i*chunk_size*2, 0, j*chunk_size*2)
			node.name = str("x", i, "z", j)
			chunks.add_child(node)

func move_player():
	@warning_ignore("integer_division")
	var half_size = size/2
	var pos = Vector3(half_size*2, 0, half_size*2)
	pos.y = abs(get_height(half_size, half_size)) * 2 + y_offset*2 +4
	print("Player Y Position: " + str(pos.y))
	player.position = pos

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

func GENERATE():
	#set rand_noise seed:
	rand_noise.seed = noise.seed
	
	print("Generating Gridmap")
	update_gridmap()
	generate_features()
	create_gridmap_chunks()
	render_gridmap()
	move_player()
	await get_tree().process_frame
	print("Done!")

func _ready():
	if global.did_generate_level == false:
		global.show_loading_screen(true)
		await get_tree().process_frame
		GENERATE()
		await get_tree().process_frame
		global.show_loading_screen(false)
		global.did_generate_level = true

##At Runtime:

func destroy_block(world_coord):
	var map_pos = local_to_map(world_coord)
	var chunk = str("x", floor(map_pos.x/chunk_size), "z", floor(map_pos.z/chunk_size))
	var chunk_node = chunks.get_node(chunk)
	set_cell_item(map_pos, -1)
	update_single_chunk(chunk_node, floor(map_pos.x/chunk_size), floor(map_pos.z/chunk_size), map_pos)

func place_block(world_coord, index):
	print("Placed Block index: " + str(index))
	var map_pos = local_to_map(world_coord)
	var chunk = str("x", floor(map_pos.x/chunk_size), "z", floor(map_pos.z/chunk_size))
	var chunk_node = chunks.get_node(chunk)
	set_cell_item(map_pos, index)
	update_single_chunk(chunk_node, floor(map_pos.x/chunk_size), floor(map_pos.z/chunk_size), map_pos)

func save_level_to_file(path: String):
	var save_gridmap: GridMap = self
	var save_player = player
	var scene = PackedScene.new()
	
	scene.pack(save_player)
	scene.pack(save_gridmap)
	print(scene)
	var result = scene.pack(save_gridmap)
	if result == OK:
		var error = ResourceSaver.save(scene, ("user://levels/" + path + ".tscn"))
		print("Errorlevel Save Level: " + str(error))

func load_level_from_file(file: String):
	global.show_loading_screen(true)
	await get_tree().process_frame
	name = "GridMapOld"
	var scene = load("user://levels/" + file)
	var node = scene.instantiate()
	
	#very goofy code idk why but it works.
	$"..".add_child(node)
	await get_tree().process_frame
	#$"../GridMap".create_gridmap_chunks()
	$"../GridMap".render_gridmap()
	$"../GridMap".move_player()
	
	queue_free()
	await get_tree().process_frame
	global.show_loading_screen(false)

extends Node3D

const player_scene = preload("res://scenes/player.tscn")
var physics_tick_counter = 0
var tick_counter = 0

var player: CharacterBody3D
@onready var mainmenu: Control = $UI/MainMenu
@onready var grid_map: GridMap = $GridMap
@onready var chat: Control = $UI/Chat
@onready var sound: Node3D = $Sounds
@onready var blockSelect: Node3D = $BlockSelect
@onready var objects: Node3D = $Objects
@onready var entities: Node3D = $Entities
@onready var music_timer: Timer = $MusicTimer
@onready var music_player: AudioStreamPlayer = $MusicStreamPlayer

func _ready():
	music_player.finished.connect(start_music_timer)

func add_player(id, pos: Vector3):
	#id = 0
	print_rich("[INFO] Add Player (non RPC): [b]", id)
	var player_node = player_scene.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	player_node.spawn_position = pos
	add_child(player_node)
	player = player_node
	return get_node("%s" % str(id))

@rpc("call_local", "any_peer")
func add_player_multiplayer(id, pos: Vector3):
	print_rich("[INFO] Add Player (RPC) [b]: ", id)
	var player_node = player_scene.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	player_node.spawn_position = pos
	add_child(player_node)
	if is_multiplayer_authority():
		player = player_node
	return get_node("%s" % str(id))

func _process(_delta: float) -> void:
	if mainmenu.button_pressed == "singleplayer":
		mainmenu.visible = false
		mainmenu.button_pressed = ""
		grid_map.size = mainmenu.size_box.value
		global.change_title_extension("Singleplayer")
		global.hide_popup()
		global.in_mainmenu = false
		
		#Singleplayer Game
		global.is_multiplayer = false
		grid_map.init_singleplayer()
	
	if mainmenu.button_pressed == "mult_host":
		mainmenu.button_pressed = ""
		mainmenu.hide()
		grid_map.size = mainmenu.size_box.value
		
		#Host Game
		global.enet_peer.create_server(global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer
		grid_map.init_host()
		await get_tree().process_frame
		upnp_start()
		
		global.change_title_extension("Multiplayer (%s)" % multiplayer.get_unique_id())
		global.in_mainmenu = false
		
	if mainmenu.button_pressed == "mult_join":
		global.show_loading_screen(true, "Joining Server...")
		mainmenu.button_pressed = ""
		mainmenu.hide()
		
		#Join Game
		global.enet_peer.create_client(mainmenu.ip_address.text, global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer
		
		global.change_title_extension("Multiplayer (%s)" % multiplayer.get_unique_id())
		global.in_mainmenu = false

func _physics_process(_delta: float) -> void:
	physics_tick_counter += 1
	if physics_tick_counter == 2:
		tick()
		physics_tick_counter = 0

func tick(): #40 tic/sec
	tick_counter += 1
	
	if objects == null or entities == null:
		print_rich("[color=yellow][WARNING] Objects or entities is null. Skipping tick.")
		return
	
	#objects
	for node in objects.get_children():
		if node.has_method("tick"):
			node.tick()
	#entities
	for node in entities.get_children():
		if node.has_method("tick"):
			node.tick()

func move_block_selection(exact_local_pos: Vector3):
	var map_pos: Vector3 = grid_map.local_to_map(exact_local_pos)
	var local_pos: Vector3 = grid_map.map_to_local(map_pos)
	
	blockSelect.position = local_pos
	return OK

func upnp_start():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
	"UPNP Discover failed! Error %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
	"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(global.PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
	"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print_rich("[color=green][SUCCESS] UPNP SETUP SUCCESS![/color] IP Address: [b]%s" % upnp.query_external_address())
	
	chat.add_message("serverplayer", "Use this IP to join to your server: %s" % upnp.query_external_address())

func start_music_timer():
	music_timer.wait_time = randi_range(40, 180)
	music_timer.start()
	
	await music_timer.timeout
	
	music_player.stream = load("res://sound/music.untitled_main_theme.ogg")
	music_player.play()

#Save and Load
func save_level_to_file(filename: String):
	var absolute_path = "user://levels/%s" % filename
	var save_gridmap = GridMap.new()
	var save_objects = Node3D.new()
	var save_metadata: Dictionary
	save_gridmap = grid_map
	save_objects = objects
	
	#Setup Folder
	if !DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_recursive_absolute(absolute_path)
	
	#METADATA
	save_metadata.gridmap_size = save_gridmap.size
	save_metadata.protocol_version = global.PROTOCOL_VERSION
	save_metadata.player = {"pos": player.position, "inventory": player.inventory, "rotation": player.rotation}
	var metadata_file = FileAccess.open("%s/metadata.bytes" % absolute_path, FileAccess.WRITE)
	metadata_file.store_var(save_metadata)
	metadata_file.close()
	
	#GRIDMAP
	var scene = PackedScene.new()
	scene.pack(save_gridmap)
	print_rich("[INFO] Saving following scene: [b]", scene)
	var result = scene.pack(save_gridmap)
	if result == OK:
		var error = ResourceSaver.save(scene, ("%s/gridmap.tscn" % absolute_path))
		print_rich("[INFO] Errorlevel Save Level Gridmap: " + str(error))
	
	#OBJECTS
	scene = PackedScene.new()
	for i in objects.get_children():
		i.owner = objects
	scene.pack(save_gridmap)
	print_rich("[INFO] Saving following scene: [b]", scene)
	var result_obj = scene.pack(save_objects)
	if result_obj == OK:
		var error = ResourceSaver.save(scene, ("%s/objects.tscn" % absolute_path))
		print_rich("[INFO] Errorlevel Save Level Gridmap: " + str(error))
	
func load_level_from_file(filename: String):
	global.show_loading_screen(true, "Loading Map...")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	var absolute_path = "user://levels/%s" % filename
	
	#Error
	if !DirAccess.dir_exists_absolute(absolute_path):
		global.show_popup("LoadError", "Directory does not exist")
		return
	if !FileAccess.file_exists("%s/gridmap.tscn" % absolute_path):
		global.show_popup("LoadError", "Gridmap.tscn does not exist")
		return
	if !FileAccess.file_exists("%s/objects.tscn" % absolute_path):
		global.show_popup("LoadError", "Objects.tscn does not exist. Try copying from another world.")
		return
	if !FileAccess.file_exists("%s/metadata.bytes" % absolute_path):
		global.show_popup("LoadError", "Metadata.bytes does not exist. Try copying from another world.")
		return
	
	var scene_gridmap = load("%s/gridmap.tscn" % absolute_path)
	var scene_objects = load("%s/objects.tscn" % absolute_path)
	var node_gridmap: GridMap = scene_gridmap.instantiate()
	var node_objects: Node3D = scene_objects.instantiate()
	var metadata_file = FileAccess.open("%s/metadata.bytes" % absolute_path, FileAccess.READ)
	var metadata = metadata_file.get_var(false)
	
	#get Saved GridMap Size
	
	print_rich("[INFO] Loaded GridMap size: [b]" + str(metadata.gridmap_size))
	
	node_objects.name = "Objects"
	node_gridmap.name = "GridMap"
	
	#Remove Old Nodes
	grid_map.queue_free()
	objects.queue_free()
	if get_node_or_null("0"):
		get_node_or_null("0").queue_free()
	await get_tree().process_frame
	
	#add nodes
	add_child(node_gridmap, true)
	if node_objects:
		add_child(node_objects, true)
	
	#Update Variables
	grid_map = get_node("GridMap")
	objects = get_node("Objects")
	
	#GridMap
	grid_map.size = int(metadata.gridmap_size)
	if global.is_multiplayer:
		grid_map.move_player(1)
	else:
		grid_map.move_player()
	grid_map.create_gridmap_chunks(true)
	grid_map.render_gridmap()
	grid_map.objects = get_node("Objects")
	grid_map.match_border_to_size()
	
	#Sand Block Fix 5000
	for node in objects.get_children():
		if node.name.contains("b19"): #If is Sand
			var sand_pos = grid_map.string_to_vector3(node.name.rstrip("b19"))
			node.free()
			
			#place new sand node
			var sand_object: Node3D = grid_map.block_nodes[1].instantiate()
			sand_object.position = grid_map.map_to_local(sand_pos)
			sand_object.name = str(sand_pos) + "b19"
			sand_object.init(sand_pos, get_node("GridMap"))
			objects.add_child(sand_object)
	
	#Player
	player.grid_map = grid_map
	player.control.visible = true
	if metadata.protocol_version >= 5: #0.11a
		player.position = metadata.player.pos
		player.inventory = metadata.player.inventory
		player.rotation = metadata.player.rotation

	
	global.show_loading_screen(false)
	global.do_not_allow_input = false

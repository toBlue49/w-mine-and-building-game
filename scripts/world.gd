extends Node3D

const player_scene = preload("res://scenes/player.tscn")
const music = [
	"res://sound/music.untitled_main_theme.ogg",
	"res://sound/music.similar_beginnings.ogg",
	"res://sound/music.differences.ogg"
]
var physics_tick_counter = 0
var tick_counter = 0

var player: CharacterBody3D
@onready var mainmenu: Control = $UI/MainMenu
@onready var grid_map: GridMapRewrite = $GridMap
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
	grid_map.spawn_position = pos
	
	print_rich("[INFO] Add Player (non RPC): [b]", id)
	var player_node = player_scene.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	add_child(player_node)
	player = player_node
	return get_node("%s" % str(id))

@rpc("call_local", "any_peer")
func add_player_multiplayer(id, pos: Vector3):
	print_rich("[INFO] Add Player (RPC) [b]: ", id)
	var player_node = player_scene.instantiate()
	player_node.name = str(id)
	player_node.position = pos
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
		global.PORT = mainmenu.ip_port_host.text
		
		#Host Game
		await get_tree().process_frame
		server_start(16)
		grid_map.init_host()
		
		global.change_title_extension("Multiplayer (%s) at %s" % [multiplayer.get_unique_id(), global.ipv4_address])
		global.in_mainmenu = false
		
	if mainmenu.button_pressed == "mult_join":
		global.show_loading_screen(true, "Joining Server...")
		mainmenu.button_pressed = ""
		mainmenu.hide()
		global.PORT = mainmenu.ip_port_join.text
		
		#Join Game
		client_start(mainmenu.ip_address.text, global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer
		
		global.change_title_extension("Multiplayer (%s) at %s" % [multiplayer.get_unique_id(), global.ipv4_address])
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

#Legacy Link to server_start()
func upnp_start():
	server_start(16)

func server_start(MAX_CLIENTS: int):
	global.enet_peer = ENetMultiplayerPeer.new()
	var server_creation_error = global.enet_peer.create_server(global.PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = global.enet_peer
	
	if server_creation_error != 0:
		print_rich("[color=red][ERROR] Could not create Server. Errorlevel: %s (%s)" % [server_creation_error, error_string(server_creation_error)])
		return
	else:
		print_rich("[INFO] Server created! Errorlevel: %s" % [error_string(server_creation_error)])
	
	var ip_return = await global.http.curl_url("https://ipinfo.io/ip")
	global.ipv4_address = ip_return.body.get_string_from_ascii()
	
	print_rich("[color=green][SUCCESS] SERVER SETUP SUCCESS![/color] Public IP Address: [b]%s" % global.ipv4_address)
	
	chat.add_message("serverplayer", "Use the following IPs to join your Server.")
	chat.add_message("serverplayer", "Public IP (port forward needed): %s" % global.ipv4_address)
	chat.add_message("serverplayer", "Local IP: %s" % get_local_ip())

func client_start(ipv4, port):
	global.enet_peer = ENetMultiplayerPeer.new()
	var client_creation_error = global.enet_peer.create_client(ipv4, port)
	multiplayer.multiplayer_peer = global.enet_peer
	
	if client_creation_error != 0:
		print_rich("[color=red][ERROR] Could not create Client. Errorlevel: %s (%s)" % [client_creation_error, error_string(client_creation_error)])
		return
	else:
		print_rich("[INFO] Client created! Errorlevel: %s" % [error_string(client_creation_error)])

func start_music_timer():
	music_timer.wait_time = randi_range(40, 180)
	music_timer.start()
	
	await music_timer.timeout
	
	music_player.stream = load(music[randi_range(0, music.size()-1)])
	music_player.play()

func spawn_entity(pos: Vector3, id: int):
	var entity = global.ENTITY_LIST[id].instantiate()
	entity.init(pos)
	entities.add_child(entity, true)

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168."):
			return ip
	
	return "0.0.0.0"

#Save and Load
func save_level_to_file(filename: String):
	var absolute_path = "user://levels/%s" % filename
	var save_gridmap: GridMapRewrite = grid_map
	var save_gridmap_data: Dictionary = {}
	var save_objects = Node3D.new()
	var save_entities = Node3D.new()
	var save_metadata: Dictionary
	save_objects = objects
	save_entities = entities
	
	#Setup Folder
	if !DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_recursive_absolute(absolute_path)
	
	#METADATA
	save_metadata.gridmap_size = save_gridmap.size
	save_metadata.protocol_version = global.PROTOCOL_VERSION
	save_metadata.save_version = global.SAVE_VERSION
	save_metadata.player = {"pos": player.position, "inventory": player.inventory, "rotation": player.rotation}
	var metadata_file = FileAccess.open("%s/metadata.bytes" % absolute_path, FileAccess.WRITE)
	metadata_file.store_var(save_metadata)
	metadata_file.close()
	
	#GRIDMAP
	print_rich("[INFO] Saving GridMap Data")
	for i in save_gridmap.size:
		save_gridmap_data.set(i, save_gridmap.get_data_of_x(i))
	
	var gridmap_file = FileAccess.open("%s/gridmap.bytes" % absolute_path, FileAccess.WRITE)
	gridmap_file.store_var(save_gridmap_data)
	gridmap_file.close()
	
	#OBJECTS
	var scene = PackedScene.new()
	for i in objects.get_children():
		i.owner = objects
	var result_obj = scene.pack(save_objects)
	if result_obj == OK:
		var error = ResourceSaver.save(scene, ("%s/objects.tscn" % absolute_path))
		print_rich("[INFO] Errorlevel Save Objects: " + str(error))
	
	#ENTITIES
	var scene_entity = PackedScene.new()
	for i in entities.get_children():
		i.owner = entities
	var result_obj_entity = scene_entity.pack(save_entities)
	if result_obj_entity == OK:
		var error = ResourceSaver.save(scene_entity, ("%s/entity.tscn" % absolute_path))
		print_rich("[INFO] Errorlevel Save Entity: " + str(error))

func load_level_from_file(filename: String):
	global.show_loading_screen(true, "Loading Map...")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	var absolute_path = "user://levels/%s" % filename
	
	#Load files
	
	if !DirAccess.dir_exists_absolute(absolute_path):
		global.show_popup("LoadError", "Directory does not exist!")
		return
	
	if !FileAccess.file_exists("%s/metadata.bytes" % absolute_path):
		global.show_popup("Load Error", "Metadata.bytes does not exist!")
		return
	var metadata_file = FileAccess.open("%s/metadata.bytes" % absolute_path, FileAccess.READ)
	var metadata = metadata_file.get_var(false)
	
	if !FileAccess.file_exists("%s/gridmap.bytes" % absolute_path):
		global.show_popup("Load Error", "Gridmap.tscn does not exist!")
		return
	var gridmap_file = FileAccess.open("%s/gridmap.bytes" % absolute_path, FileAccess.READ)
	var gridmap: Dictionary = gridmap_file.get_var(false)
	
	if !FileAccess.file_exists("%s/objects.tscn" % absolute_path):
		var do_continue: bool = await global.show_popup("Load Error", "Objects.tscn does not exist. Skipping will create a new file.", true)
		if !do_continue: return
	var scene_objects = load("%s/objects.tscn" % absolute_path)
	var node_objects: Node3D = scene_objects.instantiate() if scene_objects else Node3D.new()
	
	if metadata.save_version <= 0:
		if !FileAccess.file_exists("%s/entity.tscn" % absolute_path):
			var do_continue: bool = await global.show_popup("Load Error", "Entity.tscn does not exist. Skipping will create a new file.", true)
			if !do_continue: return
	var scene_entities = load("%s/entity.tscn" % absolute_path)
	var node_entities: Node3D = scene_entities.instantiate() if scene_entities else Node3D.new()
	
	print_rich("[INFO] Loaded GridMap size: [b]" + str(metadata.gridmap_size))
	
	node_objects.name = "Objects"
	node_entities.name = "Entities"
	
	#Remove Old Nodes
	objects.queue_free()
	entities.queue_free()
	if get_node_or_null("0"):
		get_node_or_null("0").queue_free()
	await get_tree().process_frame
	
	#add nodes
	if node_objects:
		add_child(node_objects, true)
	if node_entities:
		add_child(node_entities, true)
	
	#Update Variables
	grid_map = get_node("GridMap")
	objects = get_node("Objects")
	entities = get_node("Entities")
	
	#GridMap
	grid_map.setup_cell_data(int(metadata.gridmap_size))
	grid_map.size = int(metadata.gridmap_size)
	
	for i in int(metadata.gridmap_size):
		grid_map.set_data_of_x(i, gridmap.get(i))
	
	grid_map.create_gridmap_chunks(true)
	grid_map.render_all_cells()
	grid_map.objects = get_node("Objects")
	grid_map.match_border_to_size()
	
	#Player
	if global.is_multiplayer:
		grid_map.move_player(1)
	else:
		grid_map.move_player()
	
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

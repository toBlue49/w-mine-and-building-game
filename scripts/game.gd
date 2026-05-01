extends Node

const PORT = 9555
const MAIN_TITLE = "W Mine and Building Game"
const PROTOCOL_VERSION = 5
const ENTITY_LIST: Array = [
	preload("res://scenes/entity/test_entity.tscn"),
	preload("res://scenes/entity/pig.tscn"),
	preload("res://scenes/entity/dropped_item.tscn")
]

var gamemode = SURVIVAL
var show_debug = false
var config = ConfigFile.new()
var do_not_allow_input = false
var player_name = "DEFAULTNAME"
var enet_peer = ENetMultiplayerPeer.new()
var is_multiplayer = false
var loaded_scene = ""
var did_generate_level = false
var in_mainmenu = true
var block_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/block_data.json"))
var item_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/item_data.json"))
var drops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/drops.json"))
@onready var SceneContainer = $Scene
@onready var GlobalControl = $GlobalControl
@onready var request: Node = $request

var settings: Dictionary = {
	"graphics": {
		"max_fps": 300,
		"vsync": false,
		"fullscreen": false
	},
	"input_other": {
		"sensitivity": 0.002
	},
	"input": {
		"move_forward": {"mouse": false, "key": -1},
		"move_backward": {"mouse": false, "key": -1},
		"move_left": {"mouse": false, "key": -1},
		"move_right": {"mouse": false, "key": -1},
		"world_place": {"mouse": false, "key": -1},
		"world_destroy": {"mouse": false, "key": -1},
		"move_fly_down": {"mouse": false, "key": -1},
		"hotbar_up": {"mouse": false, "key": -1},
		"hotbar_down": {"mouse": false, "key": -1},
		"ui_crafting": {"mouse": false, "key": -1},
		"move_sprint": {"mouse": false, "key": -1},
		"move_jump": {"mouse": false, "key": -1}
	},
	"audio": {
		"music": 0.0,
		"sound": 0.0
	}
}

enum {CREATIVE, SURVIVAL}
enum BLOCK{
	GRASS, STONE, DIRT, LOG, LEAVES, PLANKS, GLASS, LIGHT, CONCRETE_WHITE, CONCRETE_GRAY, CONCRETE_YELLOW, CONCRETE_ORANGE, CONCRETE_GREEN_YELLOW, CONCRETE_LIME, CONCRETE_CYAN, CONCRETE_BLUE, CONCRETE_VIOLET, CONCRETE_MAGENTA, CONCRETE_PINK, SAND, RUBY_ORE, IRON_ORE, DIAMOND_ORE
}#  0      1      2     3    4       5       6      7      8               9              10               11               12                     13             14             15             16               17                18             19    20        21        22
enum ITEM{
	TESTITEM, WOOD_PICKAXE, WOOD_AXE, WOOD_SHOVEL, STONE_PICKAXE, STONE_AXE, STONE_SHOVEL, IRON_PICKAXE, IRON_AXE, IRON_SHOVEL, DIAMOND_PICKAXE, DIAMOND_AXE, DIAMOND_SHOVEL, RUBY_PICKAXE, RUBY_AXE, RUBY_SHOVEL, RAW_PORKCHOP, COOKED_PORKCHOP
}#  0         1             2         3            4              5          6             7             8         9            10               11           12              13            14        15           16            17
enum ENTITY{
	TEST_ENTITY, PIG, ITEM
}
enum itmType{BLOCK, ITEM}#  0      1

func _ready():
	await get_tree().process_frame
	load_settings()
	load_scene("res://scenes/world.tscn")
	
	for argument in OS.get_cmdline_args():
		if argument == "--force-survival":
			print_rich("[INFO] force-survival")
			global.gamemode = SURVIVAL
		if argument == "--force-creative":
			print_rich("[INFO] force-creative")
			global.gamemode = CREATIVE
	
	#Create Folder
	var dir: DirAccess = DirAccess.open("user://")
	var dir_path = "user://levels"
	if dir.dir_exists(dir_path):
		print_rich("[INFO] [b]Levels folder exists!")
	else:
		dir.make_dir(dir_path)
		print_rich("[INFO] [b]Creating levels folder!")

func load_settings():
	config.load("user://data.cfg")
	print_rich("[INFO] Loading settings")
	
	settings.graphics.max_fps = config.get_value("settings", "graphics.max_fps", settings.graphics.max_fps)
	settings.graphics.vsync = config.get_value("settings", "graphics.vsync", settings.graphics.vsync)
	settings.graphics.fullscreen = config.get_value("settings", "graphics.fullscreen", settings.graphics.fullscreen)
	settings.audio.music = config.get_value("settings", "audio.music", settings.audio.music)
	settings.audio.sound = config.get_value("settings", "audio.sound", settings.audio.sound)
	
	#Input Action
	for input_str in settings.input:
		var input = settings.input.get(input_str)
		
		#Load
		var config_input = config.get_value("settings", "input.%s" % input_str, -1)
		if !config_input is int:
			input = config_input
		
		if input.key == -1:
			return
		else:
			if input.mouse == true:
				var new_mouse_input_event = InputEventMouseButton.new()
				new_mouse_input_event.set_button_index(input.key)
				new_mouse_input_event.double_click = false
				InputMap.action_erase_events(input_str)
				InputMap.action_add_event(input_str, new_mouse_input_event)
			else:
				var new_key_input_event = InputEventKey.new()
				new_key_input_event.physical_keycode = input.key
				InputMap.action_erase_events(input_str)
				InputMap.action_add_event(input_str, new_key_input_event)
	
	#apply settings
	Engine.max_fps = settings.graphics.max_fps #Max FPS
	if settings.graphics.vsync: #VSync
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if settings.graphics.fullscreen: #Fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"), settings.audio.music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sound"), settings.audio.sound)

func update_save_settings():
	print_rich("[INFO] Updating saved settings")
	config.set_value("settings", "graphics.max_fps", settings.graphics.max_fps)
	config.set_value("settings", "graphics.vsync", settings.graphics.vsync)
	config.set_value("settings", "graphics.fullscreen", settings.graphics.fullscreen)
	config.set_value("settings", "input_other.sensitivity", settings.input_other.sensitivity)
	config.set_value("settings", "audio.music", settings.audio.music)
	config.set_value("settings", "audio.sound", settings.audio.sound)
	
	for event_str in settings.input:
		#var event = settings.input.get(event_str)
		if InputMap.action_get_events(event_str)[0] is InputEventMouseButton == true:
			config.set_value("settings", "input.%s" % event_str, {"mouse": true, "key": InputMap.action_get_events(event_str)[0].get_button_index()})
		else:
			config.set_value("settings", "input.%s" % event_str, {"mouse": false, "key": InputMap.action_get_events(event_str)[0].get_physical_keycode()})
	
	config.save("user://data.cfg")
	load_settings()

func _physics_process(_delta: float) -> void:
	GlobalControl.get_node("frames").text = "%s FPS" % int(Engine.get_frames_per_second())

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		if global.is_multiplayer:
			if loaded_scene == "res://scenes/world.tscn":
				$"Scene/World/CanvasLayer/Chat".add_message.rpc("serverplayer", "%s disconnected." % player_name)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()
	if Input.is_action_just_pressed("ui_fullscreen"):
		var mode := DisplayServer.window_get_mode()
		var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_window else DisplayServer.WINDOW_MODE_WINDOWED)
		#set resolution if windowed
		if !is_window:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		#save fullscreen mode
		settings.graphics.fullscreen = is_window
		config.set_value("settings", "graphics.fullscreen", settings.graphics.fullscreen)
		config.save("user://data.cfg")
		print("[INFO] External Setting Save: graphics.fullscreen")
	if Input.is_action_just_pressed("ui_debug"):
		show_debug = !show_debug

func load_scene(scene_path: String): 
	for i in SceneContainer.get_child_count():
		SceneContainer.get_child(i).queue_free()
	
	await get_tree().process_frame
	var new_scene = load(scene_path) as PackedScene
	var scene_node = new_scene.instantiate()
	print_rich("[INFO] Loading Scene with name [b]'" + scene_node.name + "'[/b]")
	SceneContainer.add_child(scene_node)
	
	loaded_scene = scene_path

func show_loading_screen(state: bool, text: String = "Loading..."):
	$GlobalControl/Loading.visible = state
	if state: $GlobalControl/Loading/Label.text = text

func change_title_extension(title: String):
	if title == "[none]":
		DisplayServer.window_set_title("%s" % MAIN_TITLE)
		return
	DisplayServer.window_set_title("%s: %s" % [MAIN_TITLE, title])

func reload_scene():
	load_scene(loaded_scene)

func set_new_enet_peer(online: bool):
	if online:
		enet_peer = ENetMultiplayerPeer.new()
	else:
		enet_peer = OfflineMultiplayerPeer.new()

##Popup:

func show_popup(node: String, message: String):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$PopupMessage.show()
	var popup = $PopupMessage.get_node(node)
	popup.show()
	popup.get_node("Message").text = message
	popup.get_node("Button").connect("pressed", mainmenu_btn_pressed)

func hide_popup():
	$PopupMessage.visible = false
	$PopupMessage/ServerError.visible = false

func mainmenu_btn_pressed():
	hide_popup()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	global.did_generate_level = false
	global.is_multiplayer = false
	reload_scene()

@rpc("any_peer", "call_remote")
func disconnect_peer(id: int):
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.disconnect_peer(id)
		print_rich("[INFO] Disconnected peer %s trough RPC" % id)

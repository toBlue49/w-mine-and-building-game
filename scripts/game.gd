extends Node

const PORT = 9555
const MAIN_TITLE = "W Mine and Building Game"
const PROTOCOL_VERSION = 1

var config = ConfigFile.new()
var do_not_allow_input = false
var player_name = "DEFAULTNAME"
var enet_peer = ENetMultiplayerPeer.new()
var is_multiplayer = false
var loaded_scene = ""
var did_generate_level = false
@onready var SceneContainer = $Scene
@onready var GlobalControl = $GlobalControl
@onready var request: Node = $request

var settings: Dictionary = {
	"graphics": {
		"max_fps": 0,
		"vsync": false,
		"fullscreen": false
	}
}

func _ready():
	await get_tree().process_frame
	load_settings()
	load_scene("res://scenes/world.tscn")
	
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
	
	settings.graphics.max_fps = config.get_value("settings", "graphics.max_fps", 300)
	settings.graphics.vsync = config.get_value("settings", "graphics.vsync", false)
	settings.graphics.fullscreen = config.get_value("settings", "graphics.fullscreen", false)

	#NOTE: Input Actions are set by the key_input_node script. Loaded on player ready.

	#apply settings
	Engine.max_fps = settings.graphics.max_fps
	if settings.graphics.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if settings.graphics.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
	

func update_save_settings():
	print_rich("[INFO] Updating saved settings")
	config.set_value("settings", "graphics.max_fps", settings.graphics.max_fps)
	config.set_value("settings", "graphics.vsync", settings.graphics.vsync)
	config.set_value("settings", "graphics.fullscreen", settings.graphics.fullscreen)
	config.set_value("settings", "input.move_forward", InputMap.action_get_events("move_forward")[0].get_physical_keycode())
	config.set_value("settings", "input.move_backward", InputMap.action_get_events("move_backward")[0].get_physical_keycode())
	config.set_value("settings", "input.move_left", InputMap.action_get_events("move_left")[0].get_physical_keycode())
	config.set_value("settings", "input.move_right", InputMap.action_get_events("move_right")[0].get_physical_keycode())
	config.set_value("settings", "input.world_place", InputMap.action_get_events("world_place")[0].get_button_index())
	config.set_value("settings", "input.world_destroy", InputMap.action_get_events("world_destroy")[0].get_button_index())
	config.set_value("settings", "input.move_fly_down", InputMap.action_get_events("move_fly_down")[0].get_physical_keycode())
	config.set_value("settings", "input.hotbar_up", InputMap.action_get_events("hotbar_up")[0].get_button_index())
	config.set_value("settings", "input.hotbar_down", InputMap.action_get_events("hotbar_down")[0].get_button_index())
	
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
	if event.is_action_pressed("ui_fullscreen"):
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
		print(settings.graphics.fullscreen)

func load_scene(scene_path: String): 
	for i in SceneContainer.get_child_count():
		SceneContainer.get_child(i).free()
	
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

extends Node

const PORT = 9555
const MAIN_TITLE = "W Mine and Building Game"

var config = ConfigFile.new()
var do_not_allow_input = false
var player_name = "DEFAULTNAME"
var enet_peer = ENetMultiplayerPeer.new()
var is_multiplayer = false
var loaded_scene = ""
var did_generate_level = false
@onready var SceneContainer = $Scene
@onready var GlobalControl = $GlobalControl

func _ready():
	await get_tree().process_frame
	load_scene("res://scenes/world.tscn")
	GlobalControl.get_node("date").text = ("%02d.%02d.%02d" % [Time.get_date_dict_from_system().get("day"), Time.get_date_dict_from_system().get("month"), Time.get_date_dict_from_system().get("year")])

	#Create Folder
	var dir: DirAccess = DirAccess.open("user://")
	var dir_path = "user://levels"
	if dir.dir_exists(dir_path):
		print_rich("[INFO] [b]Levels folder exists!")
	else:
		dir.make_dir(dir_path)
		print_rich("[INFO] [b]Creating levels folder!")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()

func load_scene(scene_path: String):
	for i in SceneContainer.get_child_count():
		SceneContainer.get_child(i).queue_free()
	
	var new_scene = load(scene_path) as PackedScene
	var scene_node = new_scene.instantiate()
	print(scene_node.name)
	SceneContainer.add_child(scene_node)
	
	loaded_scene = scene_path

func show_loading_screen(state: bool):
	$GlobalControl/Loading.visible = state

func change_title_extension(title: String):
	if title == "[none]":
		DisplayServer.window_set_title("%s" % MAIN_TITLE)
		return
	DisplayServer.window_set_title("%s: %s" % [MAIN_TITLE, title])

##Popup:

func show_popup(node: String, message: String):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$PopupMessage.show()
	var popup = $PopupMessage.get_node(node)
	popup.show()
	popup.get_node("Message").text = message
	popup.get_node("Button").connect("pressed", reload_scene)

func hide_popup():
	$PopupMessage.visible = false
	$PopupMessage/ServerError.visible = false

func mainmenu_btn_pressed():
	hide_popup()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	global.did_generate_level = false
	reload_scene()

func reload_scene():
	load_scene(loaded_scene)

extends Node

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
		print("Levels folder exists!")
	else:
		dir.make_dir(dir_path)
		print("Creating levels folder!")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()

func load_scene(scene_path: String):
	for i in SceneContainer.get_child_count():
		SceneContainer.get_child(i).queue_free()
	
	var new_scene = load(scene_path) as PackedScene
	var scene_node = new_scene.instantiate()
	SceneContainer.add_child(scene_node)

func show_loading_screen(state: bool):
	$GlobalControl/Loading.visible = state

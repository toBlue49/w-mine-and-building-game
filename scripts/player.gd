extends CharacterBody3D

var SPEED = WALK_SPEED
const WALK_SPEED = 7.0
const SPRINT_SPEED = WALK_SPEED * 1.44
const JUMP_VELOCITY = 11
var sensitivity = 0.002
var selected_block = 0
var selected_hotbar_item = 0
var hotbar_items = [0, 1, 2, 3, 4, 5, 6, 8, 19, -1]
@export var fly = false
@onready var camera_3d: Camera3D = $Camera3D
@onready var raycast3d: RayCast3D = $Camera3D/RayCast3D
@onready var grid_map: GridMap = $"../GridMap"
@onready var label3d: Label3D = $Label3D
##UI
@onready var control: Control = $CanvasLayer/Control
@onready var get_save_name: VBoxContainer = $CanvasLayer/Control/Menu/GetSaveName
@onready var get_load_name: VBoxContainer = $CanvasLayer/Control/Menu/GetLoadName
@onready var background: TextureRect = $CanvasLayer/Control/Menu/Background
@onready var hotbar_selection: TextureRect = $CanvasLayer/Control/Hotbar/Selection
@onready var hotbar_node_items: Control = $CanvasLayer/Control/Hotbar/Items
@onready var block_menu: Control = $CanvasLayer/Control/BlockMenu
@onready var pause_menu: VBoxContainer = $CanvasLayer/Control/Menu/PauseMenu
@onready var settings: Control = $CanvasLayer/Control/Menu/Settings
@onready var chat: Control = $"../CanvasLayer/Chat"


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready():
	set_multiplayer_authority(str(name).to_int())
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	control.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	control.visible = true
	camera_3d.current = true
	label3d.text = global.player_name
	update_hotbar()
	
	#Connect BlockMenu Buttons
	for i in block_menu.get_node("GridContainer").get_children():
		i.connect(
			"pressed", Callable(_blockmenu_button_pressed).bind(i.name)
		)

func _input(event: InputEvent) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	#Esc to hide UI
	if Input.is_action_just_pressed("ui_cancel"):
		if settings.visible:
			settings.visible = false
			return
		if block_menu.visible:
			block_menu.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			global.do_not_allow_input = false
			return
		if chat.get_node("LineEdit").visible:
			chat.get_node("LineEdit").visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			global.do_not_allow_input = false
			return
		get_load_name.visible = false
		get_save_name.visible = false
		pause_menu.visible = not pause_menu.visible
		if pause_menu.visible:
			background.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			global.do_not_allow_input = true
		else:
			background.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			global.do_not_allow_input = false
	
	if global.do_not_allow_input: return
	
	#Toggle flight
	if !global.is_multiplayer and Input.is_action_just_pressed("move_toggle_fly"):
		fly = !fly
	
	#Mouse
	if event is InputEventMouseMotion:
		rotation.y = rotation.y - event.relative.x * sensitivity
		camera_3d.rotation.x = camera_3d.rotation.x - event.relative.y * sensitivity
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	#Sprinting
	if Input.is_action_pressed("move_sprint"):
		SPEED = SPRINT_SPEED
		camera_3d.fov = 77.5
	else:
		SPEED = WALK_SPEED
		camera_3d.fov = 75
	
	#Mouse Hotbar and Update Block Selection
	if Input.is_action_just_released("hotbar_down"):
		selected_hotbar_item += 1
		if selected_hotbar_item > 9: selected_hotbar_item = 0
	elif Input.is_action_just_released("hotbar_up"):
		selected_hotbar_item += -1
		if selected_hotbar_item < 0: selected_hotbar_item = 9
	hotbar_selection.position.x = selected_hotbar_item * 56
	selected_block = hotbar_items[selected_hotbar_item]
	
	control.get_node("BlockSelect").texture = load("res://textures/icon/" + str(selected_block) + ".png")
	
	#Block Menu
	if Input.is_action_just_released("hotbar_block_menu"):
		block_menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		global.do_not_allow_input = true

func _process(delta: float) -> void:
	if not is_multiplayer_authority() and global.is_multiplayer:
		if get_node_or_null("CanvasLayer/Control") != null:
			control.hide()

	#Server closed
	if global.enet_peer.get_connection_status() == 0 and global.is_multiplayer:
		global.show_popup("ServerError", "The multiplayer instance isn't currently active.")

	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	control.get_node("Label").text = str(position)
	set_multiplayer_authority(str(name).to_int())
	camera_3d.current = true

func _physics_process(delta: float) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if fly == false:
		if not is_on_floor():
			velocity += get_gravity() * delta
		# Handle jump.
		if Input.is_action_pressed("move_jump") and is_on_floor() and global.do_not_allow_input == false: velocity.y = JUMP_VELOCITY
	elif fly == true:
		if Input.is_action_pressed("move_fly_down"): velocity.y =- JUMP_VELOCITY
		elif Input.is_action_pressed("move_jump") and global.do_not_allow_input == false: velocity.y =+ JUMP_VELOCITY
		else: velocity.y = 0

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Vector2.ZERO
	if global.do_not_allow_input == false:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	#World changes by player
	if raycast3d.is_colliding() and global.do_not_allow_input == false:
		if Input.is_action_just_pressed("world_destroy"):
			if raycast3d.get_collider().has_method("destroy_block"):
				raycast3d.get_collider().destroy_block.rpc(raycast3d.get_collision_point() - raycast3d.get_collision_normal())
		if Input.is_action_just_pressed("world_place"):
			if raycast3d.get_collider().has_method("place_block"):
				var distancex = grid_map.local_to_map(raycast3d.global_transform.origin).x - grid_map.local_to_map(raycast3d.get_collision_point()).x
				var distancey = grid_map.local_to_map(raycast3d.global_transform.origin).y - grid_map.local_to_map(raycast3d.get_collision_point()).y
				var distancez = grid_map.local_to_map(raycast3d.global_transform.origin).z - grid_map.local_to_map(raycast3d.get_collision_point()).z
				if distancey == 1:
					if distancex == 0 and distancez == 0: return
				raycast3d.get_collider().place_block.rpc((raycast3d.get_collision_point() + raycast3d.get_collision_normal()), selected_block)

##UI Control

func update_chunk_updates(count: int):
	control.get_node("chunk_updates").text = "%s Chunk Updates" % [str(count)]

func update_hotbar():
	for i in hotbar_items.size():
		hotbar_node_items.get_node(str(i)).texture = load("res://textures/icon/" + str(hotbar_items[i]) + ".png")

func _get_save_name_pressed() -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	var filename: String = get_save_name.get_node("LineEdit").text
	grid_map.save_level_to_file(filename)
	
	background.visible = false
	get_save_name.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global.do_not_allow_input = false

func _get_load_name_pressed(button_text) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	global.show_loading_screen(true, "Loading Map...")
	control.visible = false
	print_rich("[INFO] Loading scene: [b]", button_text)
	grid_map.load_level_from_file(button_text)
	
	await get_tree().process_frame
	
	background.visible = false
	get_load_name.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#get grid_map back
	for i in 4:
		global.do_not_allow_input = false
		await get_tree().process_frame
	grid_map = $"../GridMap"
	global.show_loading_screen(false)
	control.visible = true

func open_level_folder():
	OS.shell_open(ProjectSettings.globalize_path("user://levels/"))

func _blockmenu_button_pressed(name_args: String) -> void:
	print_rich("[INFO] Selected Block in blockmenu: [b]" + name_args)
	global.do_not_allow_input = false
	block_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hotbar_items[selected_hotbar_item] = name_args.to_int()
	update_hotbar()

func _on_pause_save_button() -> void:
	if global.is_multiplayer and !multiplayer.is_server():
		return
	get_save_name.visible = true
	get_load_name.visible = false
	background.visible = true
	pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	global.do_not_allow_input = true

func _on_pause_load_button() -> void:
	if global.is_multiplayer:
		return
	background.visible = true
	get_load_name.visible = true
	get_save_name.visible = false
	pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	global.do_not_allow_input = true
	
	var dir: DirAccess = DirAccess.open("user://levels/")
	
	for i in get_load_name.get_child_count():
		if get_load_name.get_child(i) is Button:
			get_load_name.get_child(i).queue_free()
	
	dir.list_dir_begin()
	for file: String in dir.get_files():
		var scene = load("res://scenes/load_level_button.tscn")
		var node: Node = scene.instantiate()
		node.text = file
		node.pressed.connect(
			Callable(_get_load_name_pressed).bind(node.text)
		)
		if not file.containsn(".objects.tscn"):
			get_load_name.add_child(node)
	var folderbutton = Button.new()
	folderbutton.text = "Open Folder"
	folderbutton.connect("pressed", open_level_folder)
	get_load_name.add_child(folderbutton)

func _on_pause_mainmenu_button() -> void:
	##Multiplayer
	if global.is_multiplayer:
		multiplayer.multiplayer_peer.close()
	
	global.reload_scene()
	global.did_generate_level = false
	global.do_not_allow_input = false
	global.is_multiplayer = false
	global.change_title_extension("[none]")

func _on_pause_settings_button() -> void:
	settings.visible = true
	settings._ready()

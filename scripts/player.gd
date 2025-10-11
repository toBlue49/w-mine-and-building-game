extends CharacterBody3D

var SPEED = WALK_SPEED
const WALK_SPEED = 7.0
const SPRINT_SPEED = WALK_SPEED * 1.44
const JUMP_VELOCITY = 11
var sensitivity = 0.002
var selected_block = 0
@export var fly = true
@onready var camera_3d: Camera3D = $Camera3D
@onready var raycast3d: RayCast3D = $Camera3D/RayCast3D
@onready var grid_map: GridMap = $"../GridMap"
##UI
@onready var control: Control = $CanvasLayer/Control
@onready var get_save_name: VBoxContainer = $CanvasLayer/Control/Menu/GetSaveName
@onready var get_load_name: VBoxContainer = $CanvasLayer/Control/Menu/GetLoadName
@onready var background: TextureRect = $CanvasLayer/Control/Menu/Background

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready():
	set_multiplayer_authority(str(name).to_int())
	if not is_multiplayer_authority(): return
	
	control.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().process_frame
	await get_tree().process_frame	
	control.visible = true
	camera_3d.current = true

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
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
	
	#Save/Load Level
	if Input.is_action_just_pressed("level_save"):
		get_save_name.visible = true
		get_load_name.visible = false
		background.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("level_load"):
		background.visible = true
		get_load_name.visible = true
		get_save_name.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
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
			get_load_name.add_child(node)
	
	#Esc to hide UI
	if Input.is_action_just_pressed("ui_cancel"):
		background.visible = false
		get_load_name.visible = false
		get_save_name.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		if get_node_or_null("CanvasLayer/Control") != null:
			control.queue_free()
	
	if not is_multiplayer_authority(): return
	control.get_node("Label").text = str(position)
	set_multiplayer_authority(str(name).to_int())
	camera_3d.current = true
	

func _physics_process(delta: float) -> void:
	if not (str(multiplayer.get_unique_id()) == str(name)): return
	
	# Add the gravity.
	if fly == false:
		if not is_on_floor():
			velocity += get_gravity() * delta
		# Handle jump.
		if Input.is_action_pressed("move_jump") and is_on_floor(): velocity.y = JUMP_VELOCITY
	elif fly == true:
		if Input.is_action_pressed("move_fly_down"): velocity.y =- JUMP_VELOCITY
		elif Input.is_action_pressed("move_jump"): velocity.y =+ JUMP_VELOCITY
		else: velocity.y = 0

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	#Change selected Block
	if Input.is_key_pressed(KEY_1):
		selected_block = 0
	if Input.is_key_pressed(KEY_2):
		selected_block = 1
	if Input.is_key_pressed(KEY_3):
		selected_block = 2
	if Input.is_key_pressed(KEY_4):
		selected_block = 3
	if Input.is_key_pressed(KEY_5):
		selected_block = 4
	control.get_node("BlockSelect").texture = load("res://textures/icon/" + str(selected_block) + ".png")
	
	#World changes by player
	if raycast3d.is_colliding():
		if Input.is_action_just_pressed("world_destory"):
			if raycast3d.get_collider().has_method("destroy_block"):
				raycast3d.get_collider().destroy_block(raycast3d.get_collision_point() - raycast3d.get_collision_normal())
		if Input.is_action_just_pressed("world_place"):
			if raycast3d.get_collider().has_method("place_block"):
				raycast3d.get_collider().place_block((raycast3d.get_collision_point() + raycast3d.get_collision_normal()), selected_block)

##UI Control

func _get_save_name_pressed() -> void:
	if not is_multiplayer_authority(): return
	var filename: String = get_save_name.get_node("LineEdit").text
	grid_map.save_level_to_file(filename)
	
	background.visible = false
	get_save_name.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _get_load_name_pressed(button_text) -> void:
	if not is_multiplayer_authority(): return
	global.show_loading_screen(true)
	print(button_text)
	grid_map.load_level_from_file(button_text)
	
	background.visible = false
	get_load_name.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#get grid_map back
	for i in 4:
		await get_tree().process_frame
	grid_map = $"../GridMap"
	global.show_loading_screen(false)

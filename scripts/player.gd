extends CharacterBody3D

var SPEED = WALK_SPEED
const WALK_SPEED = 7.0
const SPRINT_SPEED = WALK_SPEED * 1.44
const JUMP_VELOCITY = 11
var hit_damage = 5
var spawn_position = Vector3(0, 0, 0)
var sensitivity = 0.002
var selected_block = [0, itmType.BLOCK]
var selected_hotbar_item = 0
var hotbar_items = [[1, itmType.BLOCK, 1], [2, itmType.BLOCK, 44], [19, itmType.BLOCK, 10], [], [], [], [], [], [], []]
var health = 100
var fall_timer = 0
enum itmType{
	BLOCK, ITEM
}
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
@onready var game_over_menu: VBoxContainer = $CanvasLayer/Control/Menu/GameOver
@onready var settings: Control = $CanvasLayer/Control/Menu/Settings
@onready var chat: Control = $"../CanvasLayer/Chat"
@onready var healthbar: ProgressBar = $CanvasLayer/Control/HealthBar
@onready var healthbar_label: Label = $CanvasLayer/Control/HealthBar/Label

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
	update_hotbar()
	
	#Connect BlockMenu Buttons
	for i in block_menu.get_node("GridContainer").get_children():
		i.connect(
			"pressed", Callable(_blockmenu_button_pressed).bind(i.name)
		)
	
	#Survival/Creative Mode
	if global.gamemode == global.CREATIVE:
		healthbar.visible = false

func _input(event: InputEvent) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	#Esc to hide UI
	if Input.is_action_just_pressed("ui_cancel"):
		if game_over_menu.visible == true:
			return
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
	selected_block[0] = hotbar_items[selected_hotbar_item][0]
	selected_block[1] = itmType.BLOCK #temporary
	
	if selected_block[1] == itmType.BLOCK: #NOTE: Add Item Type
		control.get_node("BlockSelect").texture = load("res://textures/icon/" + str(selected_block[0]) + ".png")
	
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
	
	#Update Player Label
	label3d.text = ("%s Health\n%s" % [clamp(round(health), 0, 100), global.player_name])
	
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	control.get_node("Label").text = "%s" % [((round(fall_timer*100))/100)]
	set_multiplayer_authority(str(name).to_int())
	camera_3d.current = true
	
	#Health
	if global.gamemode == global.SURVIVAL:
		if health == 32676: #when death, is set to 32676
			healthbar.value = 0
			healthbar_label.text = "0/100"
			healthbar_label.size.x = 78
		else: #Normal behavior
			healthbar.value = health
			healthbar_label.text = "%s/100" % roundi(health)
			healthbar_label.size.x = clamp(health*5.64, 78, 564)

	if global.gamemode == global.CREATIVE:
		health = 1000
	
	#Death
	if health <= 0:
		health = 32676
		chat.add_message.rpc("serverplayer", "%s died!" % global.player_name)
		rpc_set_visibility.rpc(false)
		global.do_not_allow_input = true
		game_over_menu.visible = true
		background.visible = true
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	
func _physics_process(delta: float) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	#Fall Damage
	if is_on_floor() and fall_timer != 0:
		if fall_timer > 0.75 and global.gamemode == global.SURVIVAL: #Give Damage
			player_hit.rpc(round((pow(fall_timer+0.25, 2))*60)/10)
		fall_timer = 0
	elif velocity.y < 0:
		fall_timer += 1*delta
	
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
			if raycast3d.get_collider().has_method("player_hit"):
				raycast3d.get_collider().player_hit.rpc(hit_damage)
			if raycast3d.get_collider().has_method("destroy_block"):
				raycast3d.get_collider().destroy_block.rpc(raycast3d.get_collision_point() - raycast3d.get_collision_normal(), true if global.gamemode == global.SURVIVAL else false)
		if Input.is_action_just_pressed("world_place"):
			if raycast3d.get_collider().has_method("place_block"):
				var distancex = grid_map.local_to_map(raycast3d.global_transform.origin).x - grid_map.local_to_map(raycast3d.get_collision_point()).x
				var distancey = grid_map.local_to_map(raycast3d.global_transform.origin).y - grid_map.local_to_map(raycast3d.get_collision_point()).y
				var distancez = grid_map.local_to_map(raycast3d.global_transform.origin).z - grid_map.local_to_map(raycast3d.get_collision_point()).z
				if distancey == 1:
					if distancex == 0 and distancez == 0: return
				if selected_block[1] == itmType.BLOCK and selected_block[0] != -1:
					raycast3d.get_collider().place_block.rpc((raycast3d.get_collision_point() + raycast3d.get_collision_normal()), selected_block[0])
					if global.gamemode == global.SURVIVAL:
						hotbar_items[selected_hotbar_item][2] -= 1
					update_hotbar()

func collect_item(new_item, test_only = false) -> Error:
	for item_count in hotbar_items.size():
		var item = hotbar_items[item_count]
		if item[0] == new_item[0] and item[1] == new_item[1]:
			#Add to stack
			if !test_only:
				await get_tree().create_timer(0.2).timeout
				hotbar_items[item_count][2] += 1
				update_hotbar()
			return OK
	#Add new item
	for item in hotbar_items:
		if item[0] == -1:
			if !test_only:
				item[0] = new_item[0]
				item[1] = new_item[1]
				item[2] = 1
				update_hotbar()
			return OK
	return FAILED

@rpc("any_peer", "call_local")
func respawn():
	health = 100
	position = spawn_position
	if not is_multiplayer_authority() and global.is_multiplayer:
		return
	rpc_set_visibility.rpc(true)
	game_over_menu.visible = false
	background.visible = false
	global.do_not_allow_input = false
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	rotation.y = 0
	camera_3d.rotation.x = 0
	for i in hotbar_items:
		i[2] = 0
	update_hotbar()

@rpc("any_peer", "call_local")
func player_hit(damage: int):
	if health != 32676: #ignore when death condition
		health -= damage

@rpc("any_peer", "call_local")
func rpc_set_visibility(state: bool):
	visible = state

######## UI Control

func update_chunk_updates(count: int):
	control.get_node("chunk_updates").text = "%s Chunk Updates" % [str(count)]

func update_hotbar():
	for item_count in hotbar_items.size():
		var item = hotbar_items[item_count]
		if item == [] or item[2] == 0:
			hotbar_items[item_count] = [-1, itmType.BLOCK, 0]
			item = [-1, itmType.BLOCK, 0]
		if item[1] == itmType.BLOCK:
			hotbar_node_items.get_node(str(item_count)).texture = load("res://textures/icon/" + str(item[0]) + ".png")
		#Label
		hotbar_node_items.get_node(str(item_count)).get_node("Count").text = str(item[2])
		if item[0] == -1:
			hotbar_node_items.get_node(str(item_count)).get_node("Count").text = ""

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
	hotbar_items[selected_hotbar_item][0] = name_args.to_int()
	hotbar_items[selected_hotbar_item][1] = itmType.BLOCK #temporary
	hotbar_items[selected_hotbar_item][2] = 99
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
	game_over_menu.visible = false
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
		global.get_node("Scene/World/CanvasLayer/Chat").add_message.rpc("serverplayer", "%s disconnected." % global.player_name)
		await get_tree().process_frame
		multiplayer.multiplayer_peer.close()
	
	global.reload_scene()
	global.did_generate_level = false
	global.do_not_allow_input = false
	global.is_multiplayer = false
	global.change_title_extension("[none]")

func _on_pause_settings_button() -> void:
	settings.visible = true
	settings._ready()

func _on_death_respawn_button() -> void:
	respawn.rpc()

class_name LivingEntity
extends CharacterBody3D

var speed: float  = 4.0
var gravity: float  = 0.05
var jump_force: float = 25.0
var spawn_pos = Vector3(-1, -1, -1)
var direction = Vector3(1, 0, 1).normalized()
var tick_counter: int = 0
var do_gravity = true
var is_invincible = false

func _ready() -> void:
	if spawn_pos != Vector3(-1, -1, -1):
		position = spawn_pos
	
	make_mesh_unique_recursive()
	
	override_ready()

func override_ready():
	pass

func override_physics_process(_delta: float):
	pass

func override_tick():
	pass

func _physics_process(delta: float) -> void:
	override_physics_process(delta)
	
	if do_gravity:
		if not is_on_floor():
			velocity += get_gravity() * gravity
	
	if velocity.x != 0 or velocity.z != 0:
		look_at(Vector3(position.x + velocity.x, position.y, position.z + velocity.z,))
	
	move_and_slide()

func tick(): #40 tic/sec
	tick_counter += 1
	
	override_tick()

func calc_velocity_with_direction(in_velocity: Vector3, in_direction: Vector3):
	in_velocity.x = in_direction.x * speed
	in_velocity.z = in_direction.z * speed
	return in_velocity

func new_random_direction() -> Vector3:
	return Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func new_collision_detector(pos: Vector3) -> Area3D:
	var node = load("res://scenes/collision_detector.tscn").instantiate()
	node.position = pos
	add_child(node)
	
	return node

func should_jump(jump_area: Area3D, not_jump_area: Area3D) -> bool:
	var area = jump_area.get_overlapping_bodies().size() > 0
	var not_area = not_jump_area.get_overlapping_bodies().size() > 0
	
	return (area and !not_area)

func tint_model(col: Color):
	for node in find_children("*"):
		if node is MeshInstance3D:
			var mesh_inst: MeshInstance3D = node
			mesh_inst.mesh.surface_get_material(0).albedo_color = col

func make_mesh_unique_recursive():
	for node in find_children("*"):
		if node is MeshInstance3D:
			var mesh_inst: MeshInstance3D = node
			mesh_inst.mesh = mesh_inst.mesh.duplicate(true)

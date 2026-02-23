extends CharacterBody3D

const speed = 4.0
const gravity = 1.0
const jump_force = 25.0
@onready var should_jump_area: Area3D = $ShouldJumpArea
@onready var should_not_jump_area: Area3D = $ShouldNotJumpArea

var tick_counter: int = 0
const change_direction_tick: int = 200
var start_pos = Vector3(0, 0, 0)
var direction = Vector3(1, 0, 1).normalized()

func init(pos: Vector3):
	start_pos = pos

func _ready() -> void:
	position = start_pos

func _physics_process(delta: float) -> void:
	#velocity = Vector3.ZERO
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if not is_on_floor():
		velocity += get_gravity() * 0.05
	elif should_jump() and is_on_floor(): velocity.y = jump_force
	
	look_at(Vector3(position.x + velocity.x, position.y, position.z + velocity.z,))
	
	move_and_slide()

func tick(): #40 tic/sec
	tick_counter += 1
	
	if tick_counter >= change_direction_tick:
		direction = new_direction()
		tick_counter = 0

func should_jump() -> bool:
	var area = should_jump_area.get_overlapping_bodies().size() > 0
	var not_area = should_not_jump_area.get_overlapping_bodies().size() > 0
	
	return (area and !not_area)

func new_direction() -> Vector3:
	return Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	

extends LivingEntity

@onready var should_jump_area: Area3D
@onready var should_not_jump_area: Area3D

const change_direction_tick: int = 200

func init(pos: Vector3):
	spawn_pos = pos
	direction = new_random_direction()

func override_ready():
	should_jump_area = new_collision_detector(Vector3(0, 1, -2))
	should_not_jump_area = new_collision_detector(Vector3(0, 3, -2))

func override_physics_process(_delta: float) -> void:
	#velocity = Vector3.ZERO
	velocity = calc_velocity_with_direction(velocity, direction)
	
	if should_jump(should_jump_area, should_not_jump_area) and is_on_floor(): velocity.y = jump_force

func override_tick(): #40 tic/sec
	if tick_counter >= change_direction_tick:
		direction = new_random_direction()
		tick_counter = 0

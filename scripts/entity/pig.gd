extends LivingEntity

var change_direction_tick = 120
var should_move = true
@onready var should_jump_area: Area3D
@onready var should_not_jump_area: Area3D

func override_ready():
	should_jump_area = new_collision_detector(Vector3(0, 1, -2))
	should_not_jump_area = new_collision_detector(Vector3(0, 3, -2))

func init(pos: Vector3):
	spawn_pos = pos
	direction = new_random_direction()

func override_tick(): #40 t/s
	if tick_counter >= change_direction_tick:
		var rand = randi_range(0, 2)
		if rand == 0:
			should_move = true
		if rand == 1:
			should_move = true
			direction = new_random_direction()
		elif rand == 2:
			should_move = false
		tick_counter = 0
	
	

func override_physics_process(_delta: float):
	if should_move:
		velocity = calc_velocity_with_direction(velocity, direction)
		if should_jump(should_jump_area, should_not_jump_area) and is_on_floor(): velocity.y = jump_force
	else:
		velocity = Vector3.ZERO
	
	

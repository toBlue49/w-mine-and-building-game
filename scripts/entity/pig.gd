extends LivingEntity

var change_direction_tick = 120
var should_move = true
var health = 30
@onready var material: StandardMaterial3D = load("res://scenes/entity/pig.tscn::StandardMaterial3D_sj77l")
@onready var should_jump_area: Area3D
@onready var should_not_jump_area: Area3D
@onready var animation_tree: AnimationTree = $AnimationTree

func override_ready():
	should_jump_area = new_collision_detector(Vector3(0, 1, -1.3))
	should_not_jump_area = new_collision_detector(Vector3(0, 3, -1.3))

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
	
	if health > 0:
		animation_tree.set("parameters/conditions/walking", should_move)
		animation_tree.set("parameters/conditions/idle", !should_move)
	
	if (should_jump_area.get_overlapping_bodies().size() > 0 and should_not_jump_area.get_overlapping_bodies().size() > 0):
		direction = new_random_direction()
	
	$Label3D.visible = global.show_debug
	if global.show_debug:
		$Label3D.text = "h: %s\ntick: %s" % [health, tick_counter]

func override_physics_process(_delta: float):
	if health <= 0:
		velocity = Vector3.ZERO
		return
	
	if should_move:
		velocity = calc_velocity_with_direction(velocity, direction)
		if should_jump(should_jump_area, should_not_jump_area) and is_on_floor(): velocity.y = jump_force
	else:
		velocity = Vector3.ZERO

@rpc("any_peer", "call_local")
func player_hit(damage):
	if is_invincible:
		return
	
	health -= damage
	
	if health <= 0:
		tint_model(Color.LIGHT_CORAL)
		animation_tree.set("parameters/conditions/death", true)
	else:
		#tint
		tint_model(Color.LIGHT_CORAL)
		is_invincible = true
		await get_tree().create_timer(0.2).timeout
		tint_model(Color.WHITE)
		is_invincible = false

func drop_item():
	var drops = global.drops.entity.pig
	var item_data: Array
	
	if drops.size()-1 == -1: #NOTE: Code copied from grid_map.gd
		return
	
	item_data = drops[randi_range(0, drops.size()-1)] #set data
	item_data[0] = int(item_data[0]) #force to int
	item_data[1] = int(item_data[1]) #force to int
	item_data[2] = int(item_data[2]) #force to int
	
	for i in item_data[2]: #create dropped item nodes
			var dropped_item = global.ENTITY_LIST[global.ENTITY.ITEM].instantiate()
			dropped_item.position = global_position + Vector3(0, 0.5, 0)
			dropped_item.name = str(global_position)
			get_parent().add_child(dropped_item, true)
			dropped_item.set_item([item_data[0], item_data[1]])
	

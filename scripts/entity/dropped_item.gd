extends RigidBody3D

var self_item = [-1, itmType.BLOCK]
var velocity = Vector3(0.0, 0.0, 0.0)
var gravity = 1
var collecting = false
var direction: Vector2
@onready var area_3d: Area3D = $Area3D
@onready var area_3d_grounded: Area3D = $Area3DGrounded
@onready var sprite_3d: Sprite3D = $Sprite3D

enum itmType{
	BLOCK, ITEM
}

func set_item(item: Array):
	if item[1] == itmType.BLOCK: #TODO: Item implementation
		sprite_3d.set_texture(load("res://textures/icon/" + str(item[0]) + ".png"))
	if item[1] == itmType.ITEM:
		sprite_3d.set_texture(load("res://textures/item/" + str(item[0]) + ".png"))
	self_item = item

func _ready() -> void:
	area_3d.connect("body_entered", body_enter)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 15.0

func body_enter(body):
	var id = 0
	if global.is_multiplayer: id = multiplayer.get_unique_id()
	if body.name == str(id):
		await get_tree().create_timer(0.2).timeout
		if body.collect_item(self_item, true) == OK:
			collecting = true
			var diff = 25*(Vector3(body.global_position.x, body.global_position.y+2, body.global_position.z) - global_position)
			velocity = diff
			gravity = 0
			await get_tree().create_timer(0.2).timeout
			body.collect_item(self_item, false)
			remove.rpc()

@rpc("any_peer", "call_local", "reliable")
func remove():
	queue_free()

func _physics_process(delta: float) -> void:
	velocity.y -= delta*gravity
	
	if !collecting:
		velocity.x = direction.x
		velocity.z = direction.y
	
	if area_3d_grounded.has_overlapping_bodies() and !collecting:
		velocity = Vector3.ZERO
		direction = Vector2.ZERO
	
	apply_central_force(velocity)
	
	$DEBUG.visible = global.show_debug
	if global.show_debug:
		$DEBUG.text = str(velocity)

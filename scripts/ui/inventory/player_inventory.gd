extends Control

const slot_id_range = [0, 40]

@export var main_inv: Control
@onready var items: Control = $Items
@onready var collision: Control = $Collision

signal slot_selection(id: int, pos: Vector2)
signal reset_selection(id: int) #moves to -64, -64

func _ready() -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	for node: Control in collision.get_children():
		node.connect("mouse_entered", func(): slot_mouse_enter(int(node.name)))
		node.connect("mouse_exited", func(): slot_mouse_exit(int(node.name)))

func inventory_size() -> int:
	return main_inv.player.inventory.size()

func slot_mouse_enter(slot_id: int):
	var slot: Control = collision.get_node(str(slot_id))
	var pos = slot.global_position
	pos.x -= 3
	
	slot_selection.emit(slot_id, pos)

func is_my_slot_id(id: int):
	return (id >= slot_id_range[0] and id <= slot_id_range[1]) #if ID is in my ID range

func slot_mouse_exit(slot_id: int):
	reset_selection.emit(slot_id)

func get_item(slot: int) -> Array:
	if slot == 40:
		return [-1, global.itmType.BLOCK, 0]
	else:
		return main_inv.player.inventory[slot]

func set_item(slot: int, item: Array):
	if slot == 40 or !is_my_slot_id(slot):
		return
	
	main_inv.player.inventory[slot] = item

func open():
	show()

func close():
	hide()

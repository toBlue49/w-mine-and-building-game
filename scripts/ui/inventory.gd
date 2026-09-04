extends Control

@export var player: CharacterBody3D
@onready var items: Control = $Items
@onready var collision: Control = $Collision
@onready var holding_item_ui: TextureRect = $HoldingItem
var holding_item: Array = [-1, global.itmType.BLOCK, 0]
var hovering_slot: int = -1

func _ready() -> void:
	for node: Control in collision.get_children():
		node.connect("mouse_entered", func(): item_slot_mouse_enter(int(node.name)))
		node.connect("mouse_exited", func(): item_slot_mouse_exit(int(node.name)))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_inventory") and !global.do_not_allow_input:
		if visible:
			close()
		else:
			open()
	
	if !visible: return
	
	if Input.is_action_just_pressed("ui_left_click") and hovering_slot != -1:
		item_slot_clicked(hovering_slot)
	
	holding_item_ui.position = get_local_mouse_position()

func item_slot_clicked(slot: int):
	var item: Array = get_item(slot)
	
	if holding_item == [-1, global.itmType.BLOCK, 0]: #Not holding an item
		if item[0] != -1: #only if slot has item
			holding_item = item
			update_holding_item()
			set_item(slot, [])
			update_inventory()
	else: #Yes, holding an item
		set_item(slot, holding_item)
		update_inventory()
		if item[0] != -1: #clicked slot has item
			holding_item = item
		else: #clicked slot has no item
			holding_item = [-1, global.itmType.BLOCK, 0]
		update_holding_item()
	
	player.update_hotbar()

func get_item(slot: int) -> Array:
	return player.inventory[slot]

func set_item(slot: int, item: Array):
	player.inventory[slot] = item

func item_slot_mouse_enter(slot: int):
	hovering_slot = slot

func item_slot_mouse_exit(slot: int):
	if hovering_slot == slot:
		hovering_slot = -1

func update_holding_item():
	if holding_item[1] == global.itmType.BLOCK:
		holding_item_ui.texture = load("res://textures/icon/" + str(holding_item[0]) + ".png")
	if holding_item[1] == global.itmType.ITEM:
		holding_item_ui.texture = load("res://textures/item/" + str(holding_item[0]) + ".png")

func update_inventory():
	for item_count in player.inventory.size():
		var item = player.inventory[item_count]
		
		#Texture
		if item == [] or (item[2] == 0 and item[0] != -1):
			player.inventory[item_count] = [-1, global.itmType.BLOCK, 0]
			item = [-1, global.itmType.BLOCK, 0]
		if item[1] == global.itmType.BLOCK:
			items.get_node(str(item_count)).texture = load("res://textures/icon/" + str(item[0]) + ".png")
		if item[1] == global.itmType.ITEM:
			items.get_node(str(item_count)).texture = load("res://textures/item/" + str(item[0]) + ".png")
		
		#Label
		items.get_node(str(item_count)).get_node("Count").text = str(item[2])
		if item[0] == -1:
			items.get_node(str(item_count)).get_node("Count").text = ""

func open():
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	global.do_not_allow_input = true
	update_inventory()

func close():
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global.do_not_allow_input = false

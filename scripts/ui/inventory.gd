extends Control

const selection_position_x: Array[float] = [357.5, 413.38, 469.18, 525.06, 580.94, 636.82, 692.77, 748.65, 804.53, 860.41]
const selection_position_y: Array[float] = [464.12, 344.12, 272.125, 200.12]
@export var player: CharacterBody3D
@onready var items: Control = $Items
@onready var collision: Control = $Collision
@onready var holding_item_ui: TextureRect = $HoldingItem
@onready var inventory_selection: Sprite2D = $InventorySelection
var holding_item: Array = [-1, global.itmType.BLOCK, 0]
var hovering_slot: int = -1

func _ready() -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	for node: Control in collision.get_children():
		node.connect("mouse_entered", func(): item_slot_mouse_enter(int(node.name)))
		node.connect("mouse_exited", func(): item_slot_mouse_exit(int(node.name)))

func _process(_delta: float) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("ui_inventory"):
		if visible:
			close()
		elif !global.do_not_allow_input:
			open()
	
	if !visible: return #don't run code after this, if inventory is not open
	
	if Input.is_action_just_pressed("ui_left_click") and hovering_slot != -1:
		item_slot_clicked(hovering_slot)
	
	holding_item_ui.position = get_local_mouse_position()
	
	if hovering_slot != -1:
		inventory_selection.position.x = selection_position_x[hovering_slot % 10]
		inventory_selection.position.y = selection_position_y[floori(hovering_slot/10.0)]
	else:
		inventory_selection.position = Vector2(-64, -64)

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
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	if holding_item[1] == global.itmType.BLOCK:
		holding_item_ui.texture = load("res://textures/icon/" + str(holding_item[0]) + ".png")
	if holding_item[1] == global.itmType.ITEM:
		holding_item_ui.texture = load("res://textures/item/" + str(holding_item[0]) + ".png")

func update_inventory():
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
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

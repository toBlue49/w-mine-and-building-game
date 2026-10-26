extends Control

@export var player: CharacterBody3D
@onready var holding_item_ui: TextureRect = $HoldingItem
@onready var inventory_selection: Sprite2D = $InventorySelection

@onready var player_inventory: Control = $Container/PlayerInventory
@onready var color_workstation: Control = $Container/ColorWorkstation
@onready var sub_inventory_list = [player_inventory, color_workstation]

var holding_item: Array = [-1, global.itmType.BLOCK, 0]
var hovering_slot: int = -1

func _ready() -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	player_inventory.connect("slot_selection", item_slot_selected)
	player_inventory.connect("reset_selection", item_slot_deselected)
	color_workstation.connect("slot_selection", item_slot_selected)
	color_workstation.connect("reset_selection", item_slot_deselected)
	
	close_all_sub_inventories()

func item_slot_selected(id: int, pos: Vector2):
	hovering_slot = id
	inventory_selection.global_position = pos

func item_slot_deselected(id: int):
	if hovering_slot == id:
		hovering_slot = -1
		inventory_selection.global_position = Vector2(-64, -64)

func _process(_delta: float) -> void:
	if global.is_multiplayer:
		if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("ui_inventory"):
		if visible:
			close()
		elif !global.do_not_allow_input:
			open([global.SUB_INV.PLAYER_INVENTORY])
	
	if !visible: return #don't run code after this, if inventory is not open
	
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
	if player_inventory.is_my_slot_id(slot): #Player Inventory
		return player_inventory.get_item(slot)
	elif color_workstation.is_my_slot_id(slot): #Color Workstation
		return color_workstation.get_item(slot)
	
	breakpoint
	print_rich("[color=yellow][WARNING] get_item() got no result. Returning air block!")
	return [-1, global.itmType.BLOCK, 0]

func set_item(slot: int, item: Array):
	if player_inventory.is_my_slot_id(slot): #Player Inventory
		player_inventory.set_item(slot, item)
	elif color_workstation.is_my_slot_id(slot):
		color_workstation.set_item(slot, item)

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
	
	for inv in [player_inventory, color_workstation]:
		for item_index in range(inv.slot_id_range[0], inv.slot_id_range[1]+1):
			var item = inv.get_item(item_index)
			
			#Texture
			if item == [] or (item[2] == 0 and item[0] != -1):
				inv.set_item(item_index, [-1, global.itmType.BLOCK, 0])
				item = [-1, global.itmType.BLOCK, 0]
			if item[1] == global.itmType.BLOCK:
				inv.items.get_node(str(item_index)).texture = load("res://textures/icon/" + str(item[0]) + ".png")
			if item[1] == global.itmType.ITEM:
				inv.items.get_node(str(item_index)).texture = load("res://textures/item/" + str(item[0]) + ".png")
			
			#Label
			inv.items.get_node(str(item_index)).get_node("Count").text = str(item[2])
			if item[0] == -1:
				inv.items.get_node(str(item_index)).get_node("Count").text = ""

func open_sub_inventory(id: int):
	sub_inventory_list[id].open()

func close_sub_inventory(id: int):
	sub_inventory_list[id].close()

func open(sub_invs: Array):
	show()
	
	##open the provided inventories
	for inv_id in sub_invs:
		open_sub_inventory(inv_id)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	global.do_not_allow_input = true
	update_inventory()

func close_all_sub_inventories():
	for inv in sub_inventory_list:
		inv.close()

func close():
	hide()
	close_all_sub_inventories()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global.do_not_allow_input = false

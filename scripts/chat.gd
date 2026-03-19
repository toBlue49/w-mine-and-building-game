extends Control

var chat = [] # [NAME, MESSAGE]
@onready var messages: VBoxContainer = $Messages
@onready var line_edit: LineEdit = $LineEdit

func create_node(text: String):
	var RichMessage = RichTextLabel.new()
	var id: String

	id = str(Engine.get_frames_drawn())
	
	RichMessage.bbcode_enabled = true
	RichMessage.fit_content = true
	RichMessage.text = text
	RichMessage.name = id
	messages.add_child(RichMessage, true, Node.INTERNAL_MODE_FRONT)
	print_rich("[CHAT] [color=white]%s" % text)
	
	return id

@rpc("call_local", "any_peer")
func add_message(player_name: String, message: String):
	var text: String
	if player_name == "serverplayer":
		text = "[color=orange]%s" % message
	else:
		text = "[color=yellow]%s: [/color]%s" % [player_name, message]
	var id = create_node(text)
	
	await get_tree().create_timer(8.0).timeout
	print_rich("[INFO] Removing Chat Message: [b]" + id)
	for i in 30:
		messages.get_node(str(id)).modulate.a = lerp(1.0, 0.0, i/30.0)
		await get_tree().create_timer(0.02).timeout
	messages.get_node(id).free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_open_chat") and !line_edit.visible and !global.in_mainmenu and !global.do_not_allow_input:
		line_edit.visible = not line_edit.visible
		line_edit.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		global.do_not_allow_input = true
		await get_tree().process_frame
		line_edit.text = ""

func _on_text_submitted(new_text: String) -> void:
	if new_text.begins_with("!"):
		run_command(new_text)
	else:
		add_message.rpc(global.player_name, new_text)
	get_node("LineEdit").visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global.do_not_allow_input = false

func run_command(cmd_string: String):
	var cmd = cmd_string.split(" ")
	
	if cmd[0] == "!fly":
		if global.is_multiplayer:
			add_message("serverplayer", "Only allowed in singleplayer!")
		else:
			global.get_node("Scene/World").grid_map.player.fly = !global.get_node("Scene/World").grid_map.player.fly
			add_message("serverplayer", "Toggled flight!")
	if cmd[0] == "!give":
		#syntax
		if cmd.size() != 4 or !(cmd[1] == "BLOCK" or cmd[1] == "ITEM") or !cmd[2].is_valid_int() or !cmd[3].is_valid_int():
			add_message("serverplayer", "Invalid syntax: !give [BLOCK/ITEM] [ID] [COUNT]")
			return
		
		#block/item id
		if cmd[1] == "BLOCK":
			if (not cmd[2].to_int() < global.BLOCK.keys().size()) or cmd[2].to_int() < 0:
					add_message("serverplayer", "Invalid BLOCK ID")
					return
		if cmd[1] == "ITEM":
			if (not cmd[2].to_int() < global.ITEM.keys().size()) or cmd[2].to_int() < 0:
				add_message("serverplayer", "Invalid ITEM ID")
				return
		
		if cmd[1] == "BLOCK":
			global.get_node("Scene/World").grid_map.player.add_multiple_items([cmd[2].to_int(), global.itmType.BLOCK, cmd[3].to_int()])
		if cmd[1] == "ITEM":
			global.get_node("Scene/World").grid_map.player.add_multiple_items([cmd[2].to_int(), global.itmType.ITEM, cmd[3].to_int()])
		add_message("serverplayer", "Gave %s ID:%s x%s" % [cmd[1], cmd[2], cmd[3]])
		
	if cmd[0] == "!clearinv":
		for i in global.get_node("Scene/World").grid_map.player.inventory: 
			i[2] = 0
		global.get_node("Scene/World").grid_map.player.update_hotbar()
		add_message("serverplayer", "Cleared Inventory!")

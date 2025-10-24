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
	
	await get_tree().create_timer(4.0).timeout
	print_rich("[INFO] Removing Chat Message: [b]" + id)
	for i in 30:
		messages.get_node(str(id)).modulate.a = lerp(1.0, 0.0, i/30.0)
		await get_tree().create_timer(0.02).timeout
	messages.get_node(id).free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_open_chat") and !line_edit.visible and global.is_multiplayer:
		line_edit.visible = not line_edit.visible
		line_edit.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		global.do_not_allow_input = true
		await get_tree().process_frame
		line_edit.text = ""

func _on_text_submitted(new_text: String) -> void:
	add_message.rpc(global.player_name, new_text)
	get_node("LineEdit").visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global.do_not_allow_input = false

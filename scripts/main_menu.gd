extends Control

@onready var ip_address: LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var name_edit: LineEdit = $MarginContainer/VBoxContainer/NameLineEdit

var button_pressed: String

func _singleplayer_pressed() -> void:
	global.player_name = name_edit.text
	if global.player_name == "":
		return
	button_pressed = "singleplayer"

func _host_mult_pressed() -> void:
	global.player_name = name_edit.text
	if global.player_name == "":
		return
	global.is_multiplayer = true
	button_pressed = "mult_host"

func _join_mult_pressed() -> void:
	global.player_name = name_edit.text
	if global.player_name == "":
		return
	global.is_multiplayer = true
	button_pressed = "mult_join"

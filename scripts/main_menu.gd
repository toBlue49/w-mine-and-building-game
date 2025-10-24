extends Control

@onready var ip_address: LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var name_edit: LineEdit = $MarginContainer/VBoxContainer/NameLineEdit
@onready var size_box: SpinBox = $MarginContainer/VBoxContainer/Singleplayer/SizeBox

var button_pressed: String

func _ready():
	global.config.load("user://data.cfg")
	name_edit.text = global.config.get_value("settings", "player_name", "")

func _singleplayer_pressed() -> void:
	global.player_name = name_edit.text
	if global.player_name == "":
		return
	global.config.set_value("settings", "player_name", global.player_name)
	global.config.save("user://data.cfg")
	global.is_multiplayer = false
	button_pressed = "singleplayer"

func _host_mult_pressed() -> void:
	global.player_name = name_edit.text
	if global.player_name == "" or global.player_name == "serverplayer":
		return
	global.config.set_value("settings", "player_name", global.player_name)
	global.config.save("user://data.cfg")
	global.is_multiplayer = true
	button_pressed = "mult_host"

func _join_mult_pressed() -> void:
	global.player_name = name_edit.text
	if global.player_name == "" or global.player_name == "serverplayer":
		return
	global.config.set_value("settings", "player_name", global.player_name)
	global.config.save("user://data.cfg")
	global.is_multiplayer = true
	button_pressed = "mult_join"

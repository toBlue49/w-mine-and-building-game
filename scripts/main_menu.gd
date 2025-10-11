extends Control

@onready var ip_adress: LineEdit = $MarginContainer/VBoxContainer/LineEdit
var button_pressed: String

func _singleplayer_pressed() -> void:
	button_pressed = "singleplayer"


func _host_mult_pressed() -> void:
	button_pressed = "mult_host"

func _join_mult_pressed() -> void:  
	button_pressed = "mult_join"

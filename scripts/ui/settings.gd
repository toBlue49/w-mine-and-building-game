extends Control


var editable = {
	"graphics": {
		"max_fps": "MarginContainer/TabContainer/Graphics/VBoxContainer/max_fps/HSlider",
		"vsync": "MarginContainer/TabContainer/Graphics/VBoxContainer/vsync/Button",
		"fullscreen": "MarginContainer/TabContainer/Graphics/VBoxContainer/fullscreen/Button"
	},
	"input": {
		"sensitivity": "MarginContainer/TabContainer/Input/ScrollContainer/VBoxContainer/sensi/HSlider"
	},
	"audio": {
		"music": "MarginContainer/TabContainer/Audio/VBoxContainer/music/HSlider",
		"sound": "MarginContainer/TabContainer/Audio/VBoxContainer/sound/HSlider",
	}
}


func _ready():
	get_node(editable.graphics.max_fps).value = global.settings.graphics.max_fps
	get_node(editable.graphics.vsync).button_pressed = global.settings.graphics.vsync
	get_node(editable.graphics.fullscreen).button_pressed = global.settings.graphics.fullscreen
	get_node(editable.input.sensitivity).value = global.settings.input_other.sensitivity * 10000
	get_node(editable.audio.music).set_volume_value(global.settings.audio.music)
	get_node(editable.audio.sound).set_volume_value(global.settings.audio.sound)
	update_toggle_button_text(get_node(editable.graphics.vsync))
	update_toggle_button_text(get_node(editable.graphics.fullscreen))
	
	#connect nodes
	get_node(editable.graphics.vsync).connect("pressed", func():
		update_toggle_button_text(get_node(editable.graphics.vsync)))
	get_node(editable.graphics.fullscreen).connect("pressed", func():
		update_toggle_button_text(get_node(editable.graphics.fullscreen)))

func _save():
	global.settings.graphics.max_fps = get_node(editable.graphics.max_fps).value
	global.settings.graphics.vsync = get_node(editable.graphics.vsync).button_pressed
	global.settings.graphics.fullscreen = get_node(editable.graphics.fullscreen).button_pressed
	global.settings.input_other.sensitivity = get_node(editable.input.sensitivity).value / 10000
	global.settings.audio.music = get_node(editable.audio.music).get_volume_value()
	global.settings.audio.sound = get_node(editable.audio.sound).get_volume_value()
	
	global.update_save_settings()
	
	#close settings
	self.visible = false

func update_toggle_button_text(this):
	if this.button_pressed:
		this.text = "On"
	else:
		this.text = "Off"

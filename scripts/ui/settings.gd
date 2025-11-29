extends Control


var editable = {
	"graphics": {
		"max_fps": "MarginContainer/TabContainer/Graphics/VBoxContainer/max_fps/HSlider",
		"vsync": "MarginContainer/TabContainer/Graphics/VBoxContainer/vsync/Button",
		"fullscreen": "MarginContainer/TabContainer/Graphics/VBoxContainer/fullscreen/Button"
	}
}


func _ready():
	get_node(editable.graphics.max_fps).value = global.settings.graphics.max_fps
	get_node(editable.graphics.vsync).button_pressed = global.settings.graphics.vsync
	get_node(editable.graphics.fullscreen).button_pressed = global.settings.graphics.fullscreen
	
	#manual toggle button text update
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
	
	global.update_save_settings()
	
	#close settings
	self.visible = false

func update_toggle_button_text(this):
	if this.button_pressed:
		this.text = "On"
	else:
		this.text = "Off"

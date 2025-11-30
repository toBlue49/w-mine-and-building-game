extends HBoxContainer
var key_array: Array
var event: InputEvent
var mouse_button_table = [
	"None",
	"MouseLeft",
	"MouseRight",
	"MouseMiddle",
	"WheelUp",
	"WheelDown",
	"WheelLeft",
	"WheelRight",
	"MouseXButton 1",
	"MouseXButton 2"
]
@export var text: String = "LABEL"
@export var input: String = "INPUT"
@onready var mainbutton: Button = $Button
@onready var panel: Panel = $Button/Panel
@onready var label: Label = $Label
@onready var vbox: VBoxContainer = $Button/Panel/ScrollContainer/MarginContainer/VBoxContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	key_array = InputMap.action_get_events(input)
	event = key_array[0]
	if event is InputEventKey:
		mainbutton.text = OS.get_keycode_string(event.get_physical_keycode())
	else:
		mainbutton.text = mouse_button_table[event.get_button_index()]
	label.text = "%s: " % [text]

	#Add Buttons to VBoxContainer
	if event is InputEventKey:
		for i in 64: #Keyboard Keys
			var new = Button.new()
			var new_key = OS.get_keycode_string(i+32)
			new.text = new_key
			new.name = str(i+32)
			new.add_theme_font_size_override("font_size", 20)
			vbox.add_child(new)
			
			vbox.get_node(str(i+32)).connect("pressed", func():
				key_selected(vbox.get_node(str(i+32)), str(i+32)))
	else:
		for i in 9: #Mouse Buttons
			var new = Button.new()
			var new_btn = mouse_button_table[i+1]
		
			new.text = new_btn
			new.name = str("M", i+1)
			new.add_theme_font_size_override("font_size", 20)
			vbox.add_child(new)
			
			vbox.get_node(str("M", i+1)).connect("pressed", func():
				mouse_selected(vbox.get_node(str("M", i+1)), str("M", i+1)))

	#NOTE: This loads the setting from the config. Normally in game.gd, but here for simpler coding.
	#Load Inputs
	if event is InputEventKey:
		var input_event = InputEventKey.new()
		input_event.set_physical_keycode(global.config.get_value("settings", "input.%s" % [input],
										ProjectSettings.get_setting("input/%s" % [input]).events[0].get_physical_keycode()))
		input_event.set_pressed(false)
		input_event.set_echo(false)
		InputMap.action_erase_events(input)
		InputMap.action_add_event(input, input_event)
	else:
		var input_event = InputEventMouseButton.new()
		input_event.set_button_index(global.config.get_value("settings", "input.%s" % [input],
										ProjectSettings.get_setting("input/%s" % [input]).events[0].get_button_index()))
		input_event.set_pressed(false)
		InputMap.action_erase_events(input)
		InputMap.action_add_event(input, input_event)

func mouse_selected(_this, key):
	#Set Button
	var key_num = key.replace("M", "")
	var input_event = InputEventMouseButton.new()
	input_event.set_button_index(int(key_num))
	input_event.set_pressed(false)
	input_event.set_double_click(false)
	InputMap.action_erase_events(input)
	InputMap.action_add_event(input, input_event)
	
	#Close Panel
	mainbutton.get_node("Panel").visible = false
	
	#Update
	key_array = InputMap.action_get_events(input)
	event = key_array[0]
	if event is InputEventKey:
		mainbutton.text = OS.get_keycode_string(event.get_physical_keycode())
	else:
		mainbutton.text = mouse_button_table[event.get_button_index()]

func key_selected(_this, key):
	#Set Key
	var input_event = InputEventKey.new()
	input_event.set_physical_keycode(int(key))
	input_event.set_pressed(false)
	input_event.set_echo(false)
	InputMap.action_erase_events(input)
	InputMap.action_add_event(input, input_event)
	
	#Close Panel
	mainbutton.get_node("Panel").visible = false
	
	#Update
	key_array = InputMap.action_get_events(input)
	event = key_array[0]
	if event is InputEventKey:
		mainbutton.text = OS.get_keycode_string(event.get_physical_keycode())
	else:
		mainbutton.text = mouse_button_table[event.get_button_index()]

func _on_mainbutton_pressed() -> void:
	#Open Panel
	mainbutton.get_node("Panel").visible = not mainbutton.get_node("Panel").visible

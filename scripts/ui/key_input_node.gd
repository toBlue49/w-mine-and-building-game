extends HBoxContainer
var key_array: Array
var event: InputEvent
var is_remapping = false
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
@onready var label: Label = $Label

func _ready() -> void:
	key_array = InputMap.action_get_events(input)
	event = key_array[0]
	
	#NOTE: This part was written with absolute pain.
	#Load Inputs

	
	if event is InputEventKey:
		mainbutton.text = OS.get_keycode_string(event.get_physical_keycode())
	else:
		mainbutton.text = mouse_button_table[event.get_button_index()]
	label.text = "%s: " % [text]
	
	mainbutton.pressed.connect(on_button_pressed.bind(mainbutton, event))

func on_button_pressed(button, event):
	if !is_remapping:
		is_remapping = true
	mainbutton.text = "Press Key.."

func _input(event):
	if is_remapping:
		if (event is InputEventKey or (event is InputEventMouseButton && event.pressed)):
			InputMap.action_erase_events(input)
			InputMap.action_add_event(input, event)
			
			if event is InputEventMouseButton:
				event.double_click = false
			
			mainbutton.text = event.as_text().trim_suffix(" (Physical)")
			
			is_remapping = false
			
			accept_event()

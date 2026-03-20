extends TextureButton

var crafting_path = "res://resources/crafting.json"
var crafting_data: Dictionary
var on_mouse = false
@export var crafting_id = "test"
@export var player: CharacterBody3D = CharacterBody3D.new()
@onready var label: Label = $Label

func _ready() -> void:
	var dict: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(crafting_path))
	crafting_data = dict.get(crafting_id, {})
	
	if crafting_data == {}:
		print_rich("[color=red][ERROR] Crafting ID '%s' not found!" % [crafting_id])
	
	#convert to int
	for item in crafting_data.needed.size():
		for entry in crafting_data.needed[item].size():
			crafting_data.needed[item][entry] = int(crafting_data.needed[item][entry])
	for entry in crafting_data.result.size():
		crafting_data.result[entry] = int(crafting_data.result[entry])
	
	#Label Text
	var label_text = ""
	label_text += "Needed:\n"
	for item in crafting_data.needed: #Needed Items
		if item[1] == global.itmType.BLOCK:
			label_text += "%sx %s\n" % [int(item[2]), global.BLOCK.keys()[item[0]]]
		if item[1] == global.itmType.ITEM:
			label_text += "%sx %s\n" % [int(item[2]), global.ITEM.keys()[item[0]]]
	
	if crafting_data.result[1] == global.itmType.BLOCK:
		label_text += "Result: %sx %s" % [int(crafting_data.result[2]), global.BLOCK.keys()[int(crafting_data.result[0])]]
	if crafting_data.result[1] == global.itmType.ITEM:
		label_text += "Result: %sx %s" % [int(crafting_data.result[2]), global.ITEM.keys()[int(crafting_data.result[0])]]
	
	label.text = label_text
	
func _process(_delta: float) -> void:
	on_mouse = get_global_rect().has_point(get_global_mouse_position())
	
	label.visible = on_mouse

func _on_pressed() -> void:
	player.craft_item(crafting_data.needed, crafting_data.result)

extends Node3D

const player = preload("res://scenes/player.tscn")
@onready var mainmenu: Control = $CanvasLayer/MainMenu
@onready var grid_map: GridMap = $GridMap


func add_player(id, pos: Vector3):
	#id = 0
	print("neuer player: ", id)
	var player_node = player.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	add_child(player_node)
	return get_node("%s" % str(id))

@rpc("call_local")
func add_player_multiplayer(id, pos: Vector3):
	print("neuer player (mult): ", id)
	var player_node = player.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	add_child(player_node)
	return get_node("%s" % str(id))

func _process(_delta: float) -> void:
	if mainmenu.button_pressed == "singleplayer":
		mainmenu.visible = false
		mainmenu.button_pressed = ""
		
		#Init Singleplayer Game
		global.is_multiplayer = false
		grid_map.init_singleplayer()
		
	if mainmenu.button_pressed == "mult_host":
		mainmenu.button_pressed = ""
		mainmenu.hide()
		global.enet_peer.create_server(global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer
		grid_map.init_host()
	
	if mainmenu.button_pressed == "mult_join":
		mainmenu.button_pressed = ""
		mainmenu.hide()
		global.enet_peer.create_client("localhost", global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer

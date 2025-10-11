extends Node3D

const player = preload("res://scenes/player.tscn")
@onready var mainmenu: Control = $CanvasLayer/MainMenu
@onready var grid_map: GridMap = $GridMap

func add_player(id, pos: Vector3):
	#id = 0
	print_rich("[INFO] Add Player (non RPC): [b]", id)
	var player_node = player.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	add_child(player_node)
	return get_node("%s" % str(id))

@rpc("call_local")
func add_player_multiplayer(id, pos: Vector3):
	print_rich("[INFO] Add Player (RPC) [b]: ", id)
	var player_node = player.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	add_child(player_node)
	return get_node("%s" % str(id))

func _process(_delta: float) -> void:
	if mainmenu.button_pressed == "singleplayer":
		mainmenu.visible = false
		mainmenu.button_pressed = ""
		global.change_title_extension("Singleplayer")
		
		#Singleplayer Game
		global.is_multiplayer = false
		grid_map.init_singleplayer()
	
	if mainmenu.button_pressed == "mult_host":
		mainmenu.button_pressed = ""
		mainmenu.hide()
		
		#Host Game
		global.enet_peer.create_server(global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer
		grid_map.init_host()
		await get_tree().process_frame
		upnp_start()
		
		global.change_title_extension("Multiplayer (%s)" % multiplayer.get_unique_id())
	
	if mainmenu.button_pressed == "mult_join":
		global.show_loading_screen(true)
		mainmenu.button_pressed = ""
		mainmenu.hide()
		
		#Join Game
		global.enet_peer.create_client(mainmenu.ip_address.text, global.PORT)
		multiplayer.multiplayer_peer = global.enet_peer
		
		global.change_title_extension("Multiplayer (%s)" % multiplayer.get_unique_id())

func upnp_start():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
	"UPNP Discover failed! Error %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
	"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(global.PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
	"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print_rich("[SUCCESS] [color=green]UPNP SETUP SUCCESS![/color] IP Address: [b]%s" % upnp.query_external_address())

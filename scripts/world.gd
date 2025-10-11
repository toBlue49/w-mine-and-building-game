extends Node3D

func add_player(id, pos: Vector3):
	var player = load("res://scenes/player.tscn")
	var player_node = player.instantiate()
	player_node.name = str(id)
	player_node.position = pos
	add_child(player_node)
	return get_node("%s" % str(id))

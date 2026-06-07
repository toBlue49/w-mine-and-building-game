extends Node3D

var map_pos: Vector3i
var tick_counter = 0
var gridmap

func init(map_pos_args: Vector3i, gridmap_args: GridMapRewrite):
	map_pos = map_pos_args
	gridmap = gridmap_args
	name = str(map_pos) + "b19"

func _ready():
	pass

func tick(): #40 tic/sec
	tick_counter += 1
	if tick_counter >= 8:
		move_down()
		tick_counter = 0

func move_down():
	if gridmap.get_cell_item(map_pos - Vector3i(0, 1, 0)) == -1:
		gridmap.set_cell_item(map_pos, -1)
		gridmap.set_cell_item(map_pos - Vector3i(0, 1, 0), 19)
		position.y -= 2
		map_pos.y -= 1
		name = str(map_pos) + "b19"

extends Node3D

var map_pos: Vector3i
var gridmap
@onready var timer: Timer = $Timer

func init(map_pos_args: Vector3i, gridmap_args: GridMap):
	map_pos = map_pos_args
	gridmap = gridmap_args
	name = str(map_pos) + "b19"

func _ready():
	timer.connect("timeout", timer_runout)


func timer_runout():
	if gridmap.get_cell_item(map_pos - Vector3i(0, 1, 0)) == -1:
		gridmap.set_cell_item(map_pos, -1)
		gridmap.set_cell_item(map_pos - Vector3i(0, 1, 0), 19)
		position.y -= 2
		map_pos.y -= 1
		name = str(map_pos) + "b19"

		#update chunk
		var chunk = str("x", floor(map_pos.x/gridmap.chunk_size), "z", floor(map_pos.z/gridmap.chunk_size))
		var chunk_node = gridmap.chunks.get_node(chunk)
		gridmap.update_single_chunk(chunk_node, floor(map_pos.x/gridmap.chunk_size), floor(map_pos.z/gridmap.chunk_size), map_pos)

extends Node3D
class_name GridMapRewrite

var cell_data_size: int
var cell_data_height: int

##Creates the empty cell_data with an given size and height.
func setup_cell_data(size: int, height:int = 128):
	var z_layer: Array[Dictionary]
	var y_layer: Array[Array]
	for z in size:
		z_layer.append({"id": -1}.duplicate())
	for y in height:
		y_layer.append(z_layer.duplicate(true))
	for x in size:
		var datablock_node: Node = load("res://scenes/gridmap_datablock.tscn").instantiate()
		datablock_node.x = x
		datablock_node.data = y_layer.duplicate(true)
		datablock_node.name = "data%s" % x
		add_child(datablock_node, true)
	
	cell_data_size = size
	cell_data_height = height

##Set the Block ID of an given cell.
##NOTE: Orientation is currently unused!
func set_cell_item(pos: Vector3i, block_id: int, _orientation: int = 0):
	if is_pos_out_of_bounds(pos):
		print_rich(pos)
		return
	
	get_node("data%s" % str(pos.x)).data[pos.y][pos.z].id = block_id

##Get the Block ID of an given cell.
##Returns -1 if the cell is empty.
func get_cell_item(pos: Vector3i) -> int:
	if is_pos_out_of_bounds(pos):
		return -1
	return get_node("data%s" % str(pos.x)).data[pos.y][pos.z].id

##Converts local position into map position
func local_to_map(local_position: Vector3) -> Vector3i:
	return Vector3i(local_position/2.0)

##Converts map position into local position
func map_to_local(map_position: Vector3i) -> Vector3:
	return Vector3(map_position*2.0) + Vector3(1, 1, 1)

func is_pos_out_of_bounds(pos: Vector3i) -> bool:
	if (pos.x >= cell_data_size or pos.z >= cell_data_size or pos.y >= cell_data_height or
		pos.x < 0              or pos.z < 0              or pos.y < 0):
			return true
	else:
		return false

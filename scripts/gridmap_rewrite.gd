extends Node3D
class_name GridMapRewrite

##Cell Data Format
##[[x[y[z{"id": blockid}]]]
var cell_data: Array = []
var cell_data_size: int
var cell_data_height: int

##Creates the empty cell_data with an given size and height.
func setup_cell_data(size: int, height:int = 128):
	var z_layer: Array
	var y_layer: Array
	var x_layer: Array
	for z in size+1:
		z_layer.append({"id": -1})
	for y in height+1:
		y_layer.append(z_layer)
	for x in size+1:
		x_layer.append(y_layer)
	
	cell_data = x_layer
	cell_data_size = size
	cell_data_height = height

##Set the Block ID of an given cell.
##NOTE: Orientation is currently unused!
func set_cell_item(pos: Vector3i, block_id: int, _orientation: int = 0):
	if pos.x > cell_data_size or pos.z > cell_data_size or pos.y > cell_data_height:
		print_rich("[INFO] Tried to set cell on an out of bounds position")
		return
	cell_data[pos.x][pos.y][pos.z].id = block_id

##Get the Block ID of an given cell.
##Returns -1 if the cell is empty.
func get_cell_item(pos: Vector3i) -> int:
	if pos.x > cell_data_size or pos.z > cell_data_size or pos.y > cell_data_height:
		print_rich("[INFO] Tried to set cell on an out of bounds position")
		return -1
	return cell_data[pos.x][pos.y][pos.z].id

##Converts local position into map position
func local_to_map(local_position: Vector3) -> Vector3i:
	return Vector3i(local_position/2.0)

##Converts map position into local position
func map_to_local(map_position: Vector3i) -> Vector3:
	return Vector3(map_position*2.0) + Vector3(1, 1, 1)

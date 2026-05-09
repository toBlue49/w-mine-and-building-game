extends Node3D
class_name GridMapRewrite

##Cell Data Format
##{Vector3i(x, y, z): {"id": block_id}}
var cell_data: Dictionary = {}

##Set Block ID of an given cell.
##NOTE: Orientation is currently unused!
func set_cell_item(pos: Vector3i, block_id: int, _orientation: int = 0):
	if cell_data.get(pos) == null:
		cell_data.set(pos, {})
	
	cell_data.get(pos).id = block_id

##Get Block ID of an given cell.
##Returns -1 if the cell does not exist.
func get_cell_item(pos: Vector3i) -> int:
	if cell_data.get(pos) == null:
		return -1
	else:
		return cell_data.get(pos).id

##Converts local position into map position
func local_to_map(local_position: Vector3) -> Vector3i:
	return Vector3i(local_position/2.0)

##Converts map position into local position
func map_to_local(map_position: Vector3i) -> Vector3:
	return Vector3(map_position*2.0)

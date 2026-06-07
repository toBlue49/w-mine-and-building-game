extends Node3D
class_name GridMapRewrite

##Saves block data of an X slice
##Uses variable "x" for saving.
class XBlockdataResource:
	extends Resource
	
	@export var x = []
	
	func _init(new: Array) -> void:
		x = new

const BASE_CELL_DATA = {"id": -1, "exposed": false}
const chunk_size = 8
var data = []
var cell_data_size: int
var cell_data_height: int
var do_neighbor_updates = false
var transparent_blocks = [-1] #-1 hardcoded, since it is air and always transparent
@onready var chunks: Node3D = $"../Chunks"

func _ready() -> void:
	#Set transparent_block array
	for i in global.block_data:
		if global.block_data.get(str(i)).transparent == true:
			transparent_blocks.append(int(i))

##Creates the empty cell_data with an given size and height.
func setup_cell_data(size: int, height:int = 128):
	data = [].duplicate()
	var z_layer: Array[Dictionary]
	var y_layer: Array[Array]
	for z in size:
		z_layer.append(BASE_CELL_DATA.duplicate(true))
	for y in height:
		y_layer.append(z_layer.duplicate(true))
	for x in size:
		data.append(XBlockdataResource.new(y_layer.duplicate(true)))
	
	cell_data_size = size
	cell_data_height = height

##Set the Block ID of an given cell.
##NOTE: Orientation is currently unused!
func set_cell_item(pos: Vector3i, block_id: int, _orientation: int = 0) -> void:
	if is_pos_out_of_bounds(pos):
		return
	
	var x = data[pos.x].x
	x[pos.y][pos.z].id = block_id
	x[pos.y][pos.z].exposed = is_cell_exposed(pos)
	data[pos.x].x = x
	
	update_render_single_cell(pos)
	
	if do_neighbor_updates:
		update_neighboring_cells(pos)

##Returns value of the given X Slice Resource
func get_data_of_x(xpos: int):
	return data[xpos].x

##Set value of the given X Slice Resource
func set_data_of_x(xpos: int, new_data: Array):
	data[xpos].x = new_data

##Get the Block ID of an given cell.
##Returns -1 if the cell is empty or out of bounds.
func get_cell_item(pos: Vector3i) -> int:
	if is_pos_out_of_bounds(pos):
		return -1
	
	return (data[pos.x].x)[pos.y][pos.z].id

##Get the Data Dictionary of an given cell.
##Returns {} if cell is out of bounds.
func get_cell_data(pos: Vector3i) -> Dictionary:
	if is_pos_out_of_bounds(pos):
		return {}
	
	return (data[pos.x].x)[pos.y][pos.z]

##Get the exposed state of an given cell
##Returns false if the cell is out of bounds.
func get_cell_exposed_state(pos: Vector3i) -> bool:
	if is_pos_out_of_bounds(pos):
		return false
	
	return (data[pos.x].x)[pos.y][pos.z].exposed

##Converts local position into map position
func local_to_map(local_position: Vector3) -> Vector3i:
	return Vector3i(local_position/2.0)

##Converts map position into local position
func map_to_local(map_position: Vector3i) -> Vector3:
	return Vector3(map_position*2.0) + Vector3(1, 1, 1)

##Updates Exposed State of neighboring cells of an certain position.
func update_neighboring_cells(pos_center: Vector3i) -> void:
	update_exposed_state_of_cell((pos_center + Vector3i(1, 0, 0)))
	update_exposed_state_of_cell((pos_center + Vector3i(-1, 0, 0)))
	update_exposed_state_of_cell((pos_center + Vector3i(0, 1, 0)))
	update_exposed_state_of_cell((pos_center + Vector3i(0, -1, 0)))
	update_exposed_state_of_cell((pos_center + Vector3i(0, 0, 1)))
	update_exposed_state_of_cell((pos_center + Vector3i(0, 0, -1)))

##Updates the exposed state of an cell at position or given cell.
func update_exposed_state_of_cell(pos: Vector3i):
	if is_pos_out_of_bounds(pos):
		return
	
	var x = data[pos.x].x
	x[pos.y][pos.z].exposed = is_cell_exposed(pos)
	data[pos.x].x = x
	update_render_single_cell(pos)

##Returns true if cell is exposed on at least one side.
##If cell exist on all sides, returns false.
func is_cell_exposed(pos: Vector3i) -> bool:
	if transparent_blocks.has(get_cell_item(pos + Vector3i(1, 0, 0))):
		return true
	if transparent_blocks.has(get_cell_item(pos + Vector3i(-1, 0, 0))):
		return true
	if transparent_blocks.has(get_cell_item(pos + Vector3i(0, 1, 0))):
		return true
	if transparent_blocks.has(get_cell_item(pos + Vector3i(0, -1, 0))):
		return true
	if transparent_blocks.has(get_cell_item(pos + Vector3i(0, 0, 1))):
		return true
	if transparent_blocks.has(get_cell_item(pos + Vector3i(0, 0, -1))):
		return true
	
	return false

##Returns true if map position is out of bounds.
func is_pos_out_of_bounds(pos: Vector3i) -> bool:
	if (pos.x >= cell_data_size or pos.z >= cell_data_size or pos.y >= cell_data_height or
		pos.x < 0              or pos.z < 0              or pos.y < 0):
			return true
	else:
		return false

##Update cell in the render gridmap if it is exposed.
func update_render_single_cell(pos: Vector3i):
	@warning_ignore("integer_division")
	var xpos = int(pos.x/chunk_size)
	@warning_ignore("integer_division")
	var zpos = int(pos.z/chunk_size)
	var gridmap: GridMap = chunks.get_node("x" + str(xpos) + "z" + str(zpos))
	
	if get_cell_exposed_state(pos):
		gridmap.set_cell_item(Vector3i(pos.x%chunk_size, pos.y, pos.z%chunk_size), get_cell_item(pos))
	else:
		gridmap.set_cell_item(Vector3i(pos.x%chunk_size, pos.y, pos.z%chunk_size), -1)

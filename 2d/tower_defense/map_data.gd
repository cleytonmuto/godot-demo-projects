extends RefCounted
class_name MapData

## Map data: rectangular grid of canyon (tower) and valley (path) cells,
## plus spawn and goal positions. Persists to user://tower_defense_map.json

enum CellType { CANYON, VALLEY }

const SAVE_PATH := "user://tower_defense_map.json"

var width: int = 12
var height: int = 8
var cells: Array = []  # 2D: cells[y][x] = CellType
var spawn: Vector2i = Vector2i(0, 0)
var goal: Vector2i = Vector2i(11, 7)


func _init() -> void:
	_clear_and_fill_default()


func _clear_and_fill_default() -> void:
	cells.clear()
	for y in height:
		var row: Array = []
		for x in width:
			row.append(CellType.CANYON)
		cells.append(row)
	# Default: valley path along top row and right column; spawn top-left, goal bottom-right
	spawn = Vector2i(0, 0)
	goal = Vector2i(width - 1, height - 1)
	for x in width:
		set_cell(x, 0, CellType.VALLEY)
	for y in height:
		set_cell(width - 1, y, CellType.VALLEY)
	set_cell(spawn.x, spawn.y, CellType.VALLEY)
	set_cell(goal.x, goal.y, CellType.VALLEY)


func get_cell(x: int, y: int) -> int:
	if x < 0 or x >= width or y < 0 or y >= height:
		return CellType.CANYON
	return cells[y][x] as int


func set_cell(x: int, y: int, type: int) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	cells[y][x] = type


func is_spawn(x: int, y: int) -> bool:
	return x == spawn.x and y == spawn.y


func is_goal(x: int, y: int) -> bool:
	return x == goal.x and y == goal.y


func set_spawn(x: int, y: int) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	set_cell(x, y, CellType.VALLEY)
	spawn = Vector2i(x, y)


func set_goal(x: int, y: int) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	set_cell(x, y, CellType.VALLEY)
	goal = Vector2i(x, y)


func new_map(w: int, h: int) -> void:
	width = clampi(w, 4, 32)
	height = clampi(h, 4, 24)
	_clear_and_fill_default()


func to_dict() -> Dictionary:
	var rows: Array = []
	for y in height:
		var row: Array = []
		for x in width:
			row.append(cells[y][x])
		rows.append(row)
	return {
		"width": width,
		"height": height,
		"cells": rows,
		"spawn_x": spawn.x,
		"spawn_y": spawn.y,
		"goal_x": goal.x,
		"goal_y": goal.y
	}


func from_dict(data: Dictionary) -> bool:
	if not data.has("width") or not data.has("height") or not data.has("cells"):
		return false
	width = int(data.width)
	height = int(data.height)
	cells = []
	for y in height:
		if y >= data.cells.size():
			return false
		var row: Array = data.cells[y]
		var new_row: Array = []
		for x in width:
			if x >= row.size():
				return false
			new_row.append(int(row[x]))
		cells.append(new_row)
	spawn = Vector2i(int(data.get("spawn_x", 0)), int(data.get("spawn_y", 0)))
	goal = Vector2i(int(data.get("goal_x", width - 1)), int(data.get("goal_y", height - 1)))
	# Ensure spawn and goal are always valley so a path can be built
	set_cell(spawn.x, spawn.y, CellType.VALLEY)
	set_cell(goal.x, goal.y, CellType.VALLEY)
	return true


func save_to_file() -> Error:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict()))
	file.close()
	return OK


func _cell_id(x: int, y: int) -> int:
	return y * width + x


func _id_to_cell(id: int) -> Vector2i:
	return Vector2i(id % width, id / width)


## Returns path from spawn to goal as array of grid cells (Vector2i). Only valley cells. Empty if no path.
func get_path_spawn_to_goal() -> PackedVector2Array:
	var astar := AStar2D.new()
	for y in height:
		for x in width:
			if get_cell(x, y) != CellType.VALLEY:
				continue
			var id := _cell_id(x, y)
			astar.add_point(id, Vector2(x, y))
	for y in height:
		for x in width:
			if get_cell(x, y) != CellType.VALLEY:
				continue
			var id := _cell_id(x, y)
			for dx in [-1, 1]:
				var nx: int = x + dx
				if nx >= 0 and nx < width and get_cell(nx, y) == CellType.VALLEY:
					astar.connect_points(id, _cell_id(nx, y))
			for dy in [-1, 1]:
				var ny: int = y + dy
				if ny >= 0 and ny < height and get_cell(x, ny) == CellType.VALLEY:
					astar.connect_points(id, _cell_id(x, ny))
	var start_id := _cell_id(spawn.x, spawn.y)
	var end_id := _cell_id(goal.x, goal.y)
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return PackedVector2Array()
	var id_path: PackedInt64Array = astar.get_id_path(start_id, end_id)
	var result := PackedVector2Array()
	for id in id_path:
		var p := astar.get_point_position(id)
		result.append(Vector2(p.x, p.y))
	return result


func load_from_file() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return err
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	if not from_dict(data):
		return ERR_PARSE_ERROR
	return OK

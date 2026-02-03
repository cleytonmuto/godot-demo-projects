extends Control

## Draws the map grid: canyon (brown), valley (dark blue), spawn and goal markers.

var map_data: MapData
var cell_size: int = 48

const COLOR_CANYON := Color(0.45, 0.35, 0.25, 1.0)
const COLOR_VALLEY := Color(0.15, 0.2, 0.4, 1.0)
const COLOR_SPAWN_TINT := Color(0.3, 0.8, 0.3, 0.55)
const COLOR_GOAL_TINT := Color(0.8, 0.25, 0.25, 0.55)
const COLOR_GRID := Color(0.2, 0.2, 0.2, 0.9)


func _draw() -> void:
	if map_data == null:
		return
	for y in map_data.height:
		for x in map_data.width:
			var rect := Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
			var cell_type := map_data.get_cell(x, y)
			var color: Color
			if cell_type == MapData.CellType.CANYON:
				color = COLOR_CANYON
			else:
				color = COLOR_VALLEY
			draw_rect(rect, color)
			if map_data.is_spawn(x, y):
				draw_rect(rect, COLOR_SPAWN_TINT)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(cell_size * 0.25, cell_size * 0.65), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			elif map_data.is_goal(x, y):
				draw_rect(rect, COLOR_GOAL_TINT)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(cell_size * 0.2, cell_size * 0.65), "G", HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			draw_rect(rect, COLOR_GRID, false)

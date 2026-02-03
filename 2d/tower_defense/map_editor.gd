extends Control

## Map Editor: edit canyon (brown) / valley (dark blue) cells, set spawn and goal.
## Persists map to user://tower_defense_map.json. Play button launches game with saved map.

enum Tool { CANYON, VALLEY, SPAWN, GOAL }

const CELL_SIZE := 48

var map_data: MapData
var current_tool: Tool = Tool.VALLEY

@onready var grid_panel: Panel = $MarginContainer/VBox/GridPanel
@onready var grid_display: Control = $MarginContainer/VBox/GridPanel/GridDisplay
@onready var tool_canyon: Button = $MarginContainer/VBox/Toolbar/ToolCanyon
@onready var tool_valley: Button = $MarginContainer/VBox/Toolbar/ToolValley
@onready var tool_spawn: Button = $MarginContainer/VBox/Toolbar/ToolSpawn
@onready var tool_goal: Button = $MarginContainer/VBox/Toolbar/ToolGoal
@onready var btn_new: Button = $MarginContainer/VBox/Toolbar/BtnNew
@onready var btn_load: Button = $MarginContainer/VBox/Toolbar/BtnLoad
@onready var btn_save: Button = $MarginContainer/VBox/Toolbar/BtnSave
@onready var btn_play: Button = $MarginContainer/VBox/Toolbar/BtnPlay
@onready var status_label: Label = $MarginContainer/VBox/StatusLabel
@onready var back_btn: Button = $MarginContainer/VBox/BackBtn


func _ready() -> void:
	map_data = MapData.new()
	_update_tool_buttons()
	tool_canyon.pressed.connect(_on_tool_canyon)
	tool_valley.pressed.connect(_on_tool_valley)
	tool_spawn.pressed.connect(_on_tool_spawn)
	tool_goal.pressed.connect(_on_tool_goal)
	btn_new.pressed.connect(_on_new)
	btn_load.pressed.connect(_on_load)
	btn_save.pressed.connect(_on_save)
	btn_play.pressed.connect(_on_play)
	back_btn.pressed.connect(_on_back)
	grid_display.map_data = map_data
	grid_display.cell_size = CELL_SIZE
	grid_display.gui_input.connect(_on_grid_input)
	_resize_grid_panel()
	_set_status("Map Editor — Paint canyon (towers) or valley (path). Set spawn and goal.")


func _resize_grid_panel() -> void:
	var w := map_data.width * CELL_SIZE
	var h := map_data.height * CELL_SIZE
	grid_panel.custom_minimum_size = Vector2(w, h)
	grid_display.custom_minimum_size = Vector2(w, h)
	grid_display.size = Vector2(w, h)
	grid_display.map_data = map_data
	grid_display.queue_redraw()


func _get_cell_at(pos: Vector2) -> Vector2i:
	var local := grid_display.get_global_transform_with_canvas().affine_inverse() * pos
	var x := int(local.x / CELL_SIZE)
	var y := int(local.y / CELL_SIZE)
	return Vector2i(x, y)


func _apply_tool(cell: Vector2i) -> void:
	if cell.x < 0 or cell.x >= map_data.width or cell.y < 0 or cell.y >= map_data.height:
		return
	match current_tool:
		Tool.CANYON:
			map_data.set_cell(cell.x, cell.y, MapData.CellType.CANYON)
		Tool.VALLEY:
			map_data.set_cell(cell.x, cell.y, MapData.CellType.VALLEY)
		Tool.SPAWN:
			map_data.set_spawn(cell.x, cell.y)
		Tool.GOAL:
			map_data.set_goal(cell.x, cell.y)
	grid_display.queue_redraw()


func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.pressed and (e.button_index == MOUSE_BUTTON_LEFT or e.button_index == MOUSE_BUTTON_RIGHT):
			var cell := _get_cell_at(e.global_position)
			_apply_tool(cell)


func _on_tool_canyon() -> void:
	current_tool = Tool.CANYON
	_update_tool_buttons()


func _on_tool_valley() -> void:
	current_tool = Tool.VALLEY
	_update_tool_buttons()


func _on_tool_spawn() -> void:
	current_tool = Tool.SPAWN
	_update_tool_buttons()


func _on_tool_goal() -> void:
	current_tool = Tool.GOAL
	_update_tool_buttons()


func _update_tool_buttons() -> void:
	tool_canyon.button_pressed = (current_tool == Tool.CANYON)
	tool_valley.button_pressed = (current_tool == Tool.VALLEY)
	tool_spawn.button_pressed = (current_tool == Tool.SPAWN)
	tool_goal.button_pressed = (current_tool == Tool.GOAL)


func _on_new() -> void:
	# Simple default size; could show a dialog
	map_data.new_map(12, 8)
	_resize_grid_panel()
	_set_status("New map 12×8. Paint and set spawn/goal, then Save.")


func _on_load() -> void:
	var err := map_data.load_from_file()
	if err != OK:
		_set_status("Load failed (no saved map or error). Save a map first.")
		return
	_resize_grid_panel()
	_set_status("Map loaded. Spawn %s, Goal %s." % [map_data.spawn, map_data.goal])


func _on_save() -> void:
	var err := map_data.save_to_file()
	if err != OK:
		_set_status("Save failed: %s" % error_string(err))
		return
	_set_status("Map saved to %s" % MapData.SAVE_PATH)


func _on_play() -> void:
	var err := map_data.save_to_file()
	if err != OK:
		_set_status("Save before Play failed.")
		return
	get_tree().change_scene_to_file("res://game.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

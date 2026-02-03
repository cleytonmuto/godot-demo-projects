extends Node2D

## Tower defense: load map, path from spawn to goal, waves of enemies, towers on canyon.
## HP = 20; each enemy reaching goal = -1 HP. Game over at 0.

const CELL_SIZE := 48
const GRID_OFFSET := Vector2(80, 100)
const START_HP := 20
const START_GOLD := 100
const TOWER_COST := 50
const ENEMY_GOLD_BASE := 8
const ENEMIES_PER_WAVE_BASE := 5
const ENEMY_SPAWN_DELAY := 0.7
const COLOR_CANYON := Color(0.45, 0.35, 0.25, 1.0)
const COLOR_VALLEY := Color(0.15, 0.2, 0.4, 1.0)
const COLOR_SPAWN := Color(0.3, 0.7, 0.3, 0.6)
const COLOR_GOAL := Color(0.8, 0.25, 0.25, 0.6)
const COLOR_GRID := Color(0.2, 0.2, 0.2, 0.7)

const ENEMY_SCENE := preload("res://enemy/enemy.tscn")
const TOWER_SCENE := preload("res://tower/tower.tscn")

var map_data: MapData
var path_cells: PackedVector2Array
var path_world: PackedVector2Array
var hp: int = START_HP
var gold: int = START_GOLD
var wave: int = 0
var wave_in_progress := false
var enemies_alive := 0
var game_over := false

@onready var tower_container: Node2D = $TowerContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var ui: CanvasLayer = $UI
@onready var hp_label: Label = $UI/MarginContainer/VBox/InfoRow/HPLabel
@onready var gold_label: Label = $UI/MarginContainer/VBox/InfoRow/GoldLabel
@onready var wave_label: Label = $UI/MarginContainer/VBox/InfoRow/WaveLabel
@onready var start_wave_btn: Button = $UI/MarginContainer/VBox/Buttons/StartWaveBtn
@onready var back_btn: Button = $UI/MarginContainer/VBox/Buttons/BackBtn
@onready var no_map_label: Label = $UI/NoMapLabel
@onready var game_over_label: Label = $UI/GameOverLabel


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	start_wave_btn.pressed.connect(_on_start_wave)
	map_data = MapData.new()
	var err := map_data.load_from_file()
	if err != OK:
		no_map_label.visible = true
		back_btn.visible = true
		$UI/MarginContainer.visible = false
		return
	no_map_label.visible = false
	_build_path()
	_update_ui()
	queue_redraw()


func _build_path() -> void:
	path_cells = map_data.get_path_spawn_to_goal()
	path_world = PackedVector2Array()
	for i in path_cells.size():
		var cell := path_cells[i]
		var cx := int(cell.x)
		var cy := int(cell.y)
		path_world.append(_cell_to_world(Vector2i(cx, cy)))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)


func _world_to_cell(world: Vector2) -> Vector2i:
	var local := world - GRID_OFFSET
	return Vector2i(int(local.x / CELL_SIZE), int(local.y / CELL_SIZE))


func _draw() -> void:
	if map_data == null:
		return
	for y in map_data.height:
		for x in map_data.width:
			var cell_type := map_data.get_cell(x, y)
			var pos := GRID_OFFSET + Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))
			var color: Color = COLOR_CANYON if cell_type == MapData.CellType.CANYON else COLOR_VALLEY
			draw_rect(rect, color)
			if map_data.is_spawn(x, y):
				draw_rect(rect, COLOR_SPAWN)
			elif map_data.is_goal(x, y):
				draw_rect(rect, COLOR_GOAL)
			draw_rect(rect, COLOR_GRID, false)


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tower(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _try_place_tower(world_pos: Vector2) -> void:
	var cell := _world_to_cell(world_pos)
	if cell.x < 0 or cell.x >= map_data.width or cell.y < 0 or cell.y >= map_data.height:
		return
	if map_data.get_cell(cell.x, cell.y) != MapData.CellType.CANYON:
		return
	if gold < TOWER_COST:
		return
	var slot_center := _cell_to_world(cell)
	for child in tower_container.get_children():
		if (child as Node2D).global_position.distance_to(slot_center) < CELL_SIZE * 0.5:
			return
	var tower := TOWER_SCENE.instantiate() as Node2D
	tower.position = slot_center
	tower_container.add_child(tower)
	gold -= TOWER_COST
	_update_ui()
	queue_redraw()


func _on_start_wave() -> void:
	if wave_in_progress or game_over:
		return
	wave += 1
	wave_in_progress = true
	start_wave_btn.disabled = true
	var count := ENEMIES_PER_WAVE_BASE + wave
	var enemy_hp := 1 + wave
	var reward := ENEMY_GOLD_BASE + wave
	enemies_alive = count
	_spawn_wave(count, enemy_hp, reward)


func _spawn_wave(count: int, enemy_hp: int, reward: int) -> void:
	for i in count:
		await get_tree().create_timer(ENEMY_SPAWN_DELAY).timeout
		if game_over:
			break
		_spawn_one_enemy(enemy_hp, reward)
	while enemies_alive > 0 and not game_over:
		await get_tree().process_frame
	wave_in_progress = false
	start_wave_btn.disabled = false
	_update_ui()


func _spawn_one_enemy(max_hp: int, reward: int) -> void:
	if path_world.is_empty():
		enemies_alive -= 1
		return
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	enemy.path = path_world.duplicate()
	enemy.max_health = max_hp
	enemy.gold_reward = reward
	enemy.died.connect(_on_enemy_died)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	enemy_container.add_child(enemy)


func _on_enemy_died(reward: int) -> void:
	gold += reward
	enemies_alive -= 1
	_update_ui()


func _on_enemy_reached_goal() -> void:
	hp -= 1
	enemies_alive -= 1
	_update_ui()
	if hp <= 0:
		_game_over()


func _game_over() -> void:
	game_over = true
	game_over_label.visible = true
	start_wave_btn.disabled = true


func _update_ui() -> void:
	hp_label.text = "HP: %d" % hp
	gold_label.text = "Gold: %d" % gold
	wave_label.text = "Wave: %d" % wave
	if wave_in_progress:
		wave_label.text += " (enemies: %d)" % enemies_alive


func _on_back() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

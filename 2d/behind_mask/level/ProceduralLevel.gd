extends Node2D
class_name ProceduralLevel

## Generates procedural levels

@export var level_width := 2048.0
@export var level_height := 768.0
@export var room_count := 5
@export var enemy_count := 8
@export var boss_count := 1

@onready var walls := $Walls
@onready var player_spawn := $PlayerSpawn
@onready var exit_door := $ExitDoor

const WALL_THICKNESS := 16.0
const ROOM_MIN_SIZE := 200.0
const ROOM_MAX_SIZE := 400.0

func _ready() -> void:
	_generate_level()

func _generate_level() -> void:
	# Generate rooms
	var rooms := _generate_rooms()
	
	# Create walls
	_create_walls()
	
	# Spawn player
	_spawn_player()
	
	# Spawn enemies
	_spawn_enemies(rooms)
	
	# Spawn boss
	_spawn_boss()
	
	# Place exit door
	_place_exit_door()

func _generate_rooms() -> Array[Rect2]:
	var rooms: Array[Rect2] = []
	
	for i in range(room_count):
		var room_size := Vector2(
			randf_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE),
			randf_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		)
		var room_pos := Vector2(
			randf_range(100, level_width - room_size.x - 100),
			randf_range(100, level_height - room_size.y - 100)
		)
		
		rooms.append(Rect2(room_pos, room_size))
	
	return rooms

func _create_walls() -> void:
	# Top wall
	_create_wall(Vector2(level_width / 2, WALL_THICKNESS / 2), Vector2(level_width, WALL_THICKNESS))
	# Bottom wall
	_create_wall(Vector2(level_width / 2, level_height - WALL_THICKNESS / 2), Vector2(level_width, WALL_THICKNESS))
	# Left wall
	_create_wall(Vector2(WALL_THICKNESS / 2, level_height / 2), Vector2(WALL_THICKNESS, level_height))
	# Right wall
	_create_wall(Vector2(level_width - WALL_THICKNESS / 2, level_height / 2), Vector2(WALL_THICKNESS, level_height))

func _create_wall(pos: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = pos
	
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)
	
	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = Color(0.4, 0.4, 0.5)
	wall.add_child(visual)
	
	walls.add_child(wall)

func _spawn_player() -> void:
	var player_scene := preload("res://player/Player.tscn")
	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(100, level_height / 2)

func _spawn_enemies(rooms: Array[Rect2]) -> void:
	var enemy_scene := preload("res://enemy/Enemy.tscn")
	
	for i in range(enemy_count):
		if rooms.is_empty():
			continue
		
		var room := rooms[randi() % rooms.size()]
		var pos := Vector2(
			randf_range(room.position.x, room.position.x + room.size.x),
			randf_range(room.position.y, room.position.y + room.size.y)
		)
		
		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = pos

func _spawn_boss() -> void:
	if boss_count <= 0:
		return
	
	var boss_scene := preload("res://enemy/BossEnemy.tscn")
	var boss := boss_scene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(level_width - 200, level_height / 2)

func _place_exit_door() -> void:
	var door_scene := preload("res://interactables/ExitDoor.tscn")
	var door := door_scene.instantiate() as ExitDoor
	door.requires_boss = boss_count > 0
	door.next_level_path = "res://ui/win_screen.tscn"
	add_child(door)
	door.global_position = Vector2(level_width - 100, level_height / 2)

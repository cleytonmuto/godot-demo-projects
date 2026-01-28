extends Node
class_name LevelManager

## Manages enemy spawning when enemies are killed

@export var enemy_scene: PackedScene
@export var spawn_radius_min := 150.0
@export var spawn_radius_max := 300.0

func _ready() -> void:
	add_to_group("level_manager")
	
	# Load default enemy scene if not set
	if not enemy_scene:
		enemy_scene = preload("res://enemy/Enemy.tscn")

func spawn_enemies(position: Vector2, count: int) -> void:
	# IMPORTANT: This can be called from within physics/collision callbacks.
	# To avoid "Can't change this state while flushing queries" errors,
	# defer the actual spawning work to the next frame.
	call_deferred("_do_spawn_enemies", position, count)

func _do_spawn_enemies(position: Vector2, count: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Count existing enemies (excluding bosses)
	var existing_enemies := get_tree().get_nodes_in_group("enemies")
	var enemy_count := 0
	for enemy in existing_enemies:
		if not enemy.is_in_group("bosses"):
			enemy_count += 1
	
	# Limit to 128 enemies max
	const MAX_ENEMIES := 128
	if enemy_count >= MAX_ENEMIES:
		return
	
	# Calculate how many we can spawn
	var can_spawn: int = min(count, MAX_ENEMIES - enemy_count)
	
	for i in range(can_spawn):
		# Find a valid spawn position
		var spawn_pos := _find_spawn_position(position, player.global_position)
		if spawn_pos == Vector2.ZERO:
			continue
		
		# Spawn enemy (deferred: we are already outside the flush)
		var enemy := enemy_scene.instantiate()
		if not enemy:
			continue
		
		get_tree().current_scene.add_child(enemy)
		enemy.global_position = spawn_pos

func _find_spawn_position(origin: Vector2, avoid_pos: Vector2, max_attempts: int = 10) -> Vector2:
	for attempt in range(max_attempts):
		var angle := randf() * TAU
		var distance := randf_range(spawn_radius_min, spawn_radius_max)
		var pos := origin + Vector2(cos(angle), sin(angle)) * distance
		
		# Check if position is valid (not too close to player, within bounds)
		if pos.distance_to(avoid_pos) < 100.0:
			continue
		
		# Check if within level bounds (rough check)
		if pos.x < 50 or pos.x > 974 or pos.y < 50 or pos.y > 718:
			continue
		
		return pos
	
	return Vector2.ZERO

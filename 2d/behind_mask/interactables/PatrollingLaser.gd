extends Node2D
class_name PatrollingLaser

## Patrolling Laser - Sweeping laser beam that kills on contact
## Guard mask deactivates it (like static lasers)

@export var sweep_distance := 200.0
@export var sweep_speed := 80.0
@export var vertical := false  # If true, sweeps vertically instead

@onready var laser_beam := $LaserBeam
@onready var emitter := $Emitter

var start_position: Vector2
var direction := 1
var player: CharacterBody2D
var mask_manager: Node
var is_active := true

func _ready() -> void:
	start_position = global_position
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		_on_mask_changed(mask_manager.current_mask)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Move back and forth
	if vertical:
		global_position.y += direction * sweep_speed * delta
		if abs(global_position.y - start_position.y) > sweep_distance / 2:
			direction *= -1
	else:
		global_position.x += direction * sweep_speed * delta
		if abs(global_position.x - start_position.x) > sweep_distance / 2:
			direction *= -1
	
	# Check for player collision
	if is_instance_valid(player) and is_active:
		var beam_rect := _get_beam_rect()
		var player_pos := player.global_position
		if beam_rect.has_point(player_pos):
			if mask_manager and mask_manager.can_collide_with_enemy():
				player.die()

func _get_beam_rect() -> Rect2:
	if vertical:
		return Rect2(global_position.x - 8, global_position.y - 50, 16, 100)
	else:
		return Rect2(global_position.x - 50, global_position.y - 8, 100, 16)

func _on_mask_changed(mask: int) -> void:
	# Guard mask deactivates patrolling lasers too
	var was_active := is_active
	is_active = mask != 1  # 1 = GUARD
	
	if is_active != was_active:
		if is_active:
			AudioManager.play_laser_activate()
		else:
			AudioManager.play_laser_deactivate()
	
	_update_visual()

func _update_visual() -> void:
	if is_active:
		laser_beam.color = Color(1, 0.2, 0.2, 0.8)
		emitter.modulate = Color.WHITE
	else:
		laser_beam.color = Color(0.3, 1, 0.3, 0.3)
		emitter.modulate = Color(0.5, 0.5, 0.5)

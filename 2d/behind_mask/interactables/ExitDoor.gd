extends Area2D
class_name ExitDoor

## Exit door - appears when boss is defeated

@export var next_level_path := ""
@export var requires_boss := false

var boss_defeated := false
var player_inside := false
var is_entering := false

@onready var visual := $Visual
@onready var collision := $CollisionShape2D

func _ready() -> void:
	# Ensure collision shape exists
	if not collision:
		collision = $CollisionShape2D
	
	# Ensure monitoring is enabled
	monitoring = true
	monitorable = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Door is always available - no boss requirement
	visible = true
	if collision:
		collision.disabled = false
	
	# Debug: Print door status
	print("ExitDoor ready - next_level: ", next_level_path, ", position: ", global_position, ", monitoring: ", monitoring, ", collision disabled: ", collision.disabled if collision else "no collision")

func _on_boss_defeated() -> void:
	boss_defeated = true
	
	# Check if all bosses are defeated
	var bosses := get_tree().get_nodes_in_group("bosses")
	var all_defeated := true
	for boss in bosses:
		if is_instance_valid(boss):
			all_defeated = false
			break
	
	if all_defeated:
		_unlock_door()

func _unlock_door() -> void:
	visible = true
	collision.disabled = false
	
	# Visual effect
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(2, 2, 2, 1), 0.2)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)
	
	AudioManager.play_level_complete()

func _on_body_entered(body: Node2D) -> void:
	print("ExitDoor: body entered - ", body.name, ", is_player: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		player_inside = true
		print("ExitDoor: Player entered - is_entering: ", is_entering, ", collision disabled: ", collision.disabled if collision else "no collision")
		# Door always works - no conditions
		if not is_entering:
			print("ExitDoor: Entering door")
			_enter_door()

func _process(_delta: float) -> void:
	# Fallback: Check if player is near door (in case body_entered doesn't fire)
	if is_entering:
		return
	
	var player := get_tree().get_first_node_in_group("player")
	if player and not player_inside:
		var distance := global_position.distance_to(player.global_position)
		if distance < 50.0:  # Within 50 pixels
			print("ExitDoor: Player near door (fallback) - distance: ", distance)
			if player.is_in_group("player"):
				player_inside = true
				_enter_door()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _enter_door() -> void:
	# Prevent multiple calls
	if is_entering or not is_inside_tree():
		print("ExitDoor: Already entering or not in tree")
		return
	
	is_entering = true
	print("ExitDoor: Loading level - ", next_level_path)
	
	# Small delay to ensure everything is ready
	await get_tree().process_frame
	
	if next_level_path != "":
		Game.load_level(next_level_path)
	else:
		# Win screen
		Game.load_level("res://ui/win_screen.tscn")

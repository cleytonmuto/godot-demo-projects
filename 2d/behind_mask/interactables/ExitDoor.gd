extends Area2D
class_name ExitDoor

## Exit door - appears when boss is defeated

@export var next_level_path := ""
@export var requires_boss := false

var boss_defeated := false
var bosses_remaining := 0
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
	
	# Add to group for easier lookup
	add_to_group("exit_doors")
	
	# Handle boss requirement: keep door locked until all bosses are defeated
	if requires_boss:
		visible = false
		if collision:
			collision.disabled = true
		
		# Connect to all existing bosses so we can unlock when they all die
		var bosses := get_tree().get_nodes_in_group("bosses")
		bosses_remaining = bosses.size()
		for boss in bosses:
			if boss.has_signal("boss_defeated") and not boss.boss_defeated.is_connected(_on_boss_defeated):
				boss.boss_defeated.connect(_on_boss_defeated)
	else:
		# No boss required - door starts unlocked
		visible = true
		if collision:
			collision.disabled = false

func _on_boss_defeated() -> void:
	# Count remaining bosses
	bosses_remaining -= 1
	if bosses_remaining <= 0:
		boss_defeated = true
		# All bosses defeated - unlock the door
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
	if body.is_in_group("player"):
		player_inside = true
		# If the door requires a boss, ensure it has been defeated
		if requires_boss and not boss_defeated:
			return
		# Door is available
		if not is_entering:
			_enter_door()

func _process(_delta: float) -> void:
	# Fallback: Check if player is near door (in case body_entered doesn't fire)
	if is_entering:
		return
	
	# If the door requires a boss and it's not dead yet, do nothing
	if requires_boss and not boss_defeated:
		return
	
	var player := get_tree().get_first_node_in_group("player")
	if player and not player_inside:
		var distance := global_position.distance_to(player.global_position)
		if distance < 50.0:  # Within 50 pixels
			if player.is_in_group("player"):
				player_inside = true
				_enter_door()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _enter_door() -> void:
	# Prevent multiple calls
	if is_entering or not is_inside_tree():
		return
	is_entering = true
	# Small delay to ensure everything is ready
	await get_tree().process_frame
	
	# Persist player health so next stage doesn't refill
	var player := get_tree().get_first_node_in_group("player")
	if player and "health" in player:
		Game.stored_player_health = player.health
	
	if next_level_path != "":
		Game.load_level(next_level_path)
	else:
		# Win screen
		Game.load_level("res://ui/win_screen.tscn")

extends Area2D
class_name Sword

## Sword weapon with fast rotating arc and neon trail

@export var damage := 1
@export var swing_radius := 120.0
@export var swing_duration := 0.3
@export var arc_angle := PI / 3.0  # 60 degree arc
@export var trail_length := 8  # Number of trail segments

var is_swinging := false
var swing_angle := 0.0
var hit_enemies: Array[BaseEnemy] = []  # Track enemies already hit this swing

@onready var visual := $Visual
@onready var collision_shape := $CollisionShape2D
@onready var hit_area := $HitArea
@onready var hit_area_collision := $HitArea/CollisionShape2D

func _ready() -> void:
	# Create visual components
	_create_visual()
	# Connect hit detection
	hit_area.body_entered.connect(_on_enemy_hit)
	# Start invisible and disabled
	visible = false
	collision_shape.disabled = true
	hit_area_collision.disabled = true

func _create_visual() -> void:
	# Create rotating arc with trail effect
	# The arc will be a segment that rotates around
	# We'll create multiple arc segments for the trail effect
	for i in range(trail_length):
		var arc := Polygon2D.new()
		arc.name = "Arc" + str(i)
		arc.z_index = 10 - i
		
		# Create arc shape
		var points := PackedVector2Array()
		var segments := 16
		var inner_radius := swing_radius * 0.85
		var outer_radius := swing_radius
		
		# Create arc segment
		for j in range(segments + 1):
			var angle := (j / float(segments)) * arc_angle
			points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
		
		# Add inner arc in reverse
		for j in range(segments, -1, -1):
			var angle := (j / float(segments)) * arc_angle
			points.append(Vector2(cos(angle), sin(angle)) * inner_radius)
		
		arc.polygon = points
		
		# Trail effect: each segment is dimmer and smaller
		var trail_alpha := 1.0 - (i / float(trail_length)) * 0.8
		var trail_scale := 1.0 - (i / float(trail_length)) * 0.3
		arc.color = Color(0.2, 0.8, 1.0, trail_alpha * 0.9)  # Neon cyan
		arc.scale = Vector2(trail_scale, trail_scale)
		
		visual.add_child(arc)

func swing() -> void:
	if is_swinging:
		return
	
	is_swinging = true
	visible = true
	collision_shape.disabled = false
	hit_area_collision.disabled = false
	swing_angle = 0.0
	hit_enemies.clear()  # Reset hit tracking
	
	# Animate the swing - fast rotation
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Rotate 360 degrees quickly
	tween.tween_method(_set_swing_angle, 0.0, TAU, swing_duration)
	
	# Fade out trail at the end
	tween.tween_property(visual, "modulate:a", 0.0, swing_duration * 0.3).set_delay(swing_duration * 0.7)
	
	# Play sound
	AudioManager.play_sword_swing()
	
	await tween.finished
	
	# Reset
	visible = false
	collision_shape.disabled = true
	hit_area_collision.disabled = true
	visual.modulate.a = 1.0
	is_swinging = false
	hit_enemies.clear()

func _set_swing_angle(angle: float) -> void:
	swing_angle = angle
	visual.rotation = angle
	
	# Update trail positions - each arc follows behind the main one
	var trail_delay := arc_angle / float(trail_length)
	for i in range(1, trail_length):
		var arc := visual.get_node_or_null("Arc" + str(i))
		if arc:
			# Each trail segment is slightly behind
			var trail_angle := angle - (trail_delay * i)
			arc.rotation = trail_angle

func _on_enemy_hit(body: Node2D) -> void:
	# Only hit enemies during active swing
	if not is_swinging:
		return
	
	if body.is_in_group("enemies") and body is BaseEnemy:
		var enemy := body as BaseEnemy
		# Prevent multiple hits on the same enemy in one swing
		if enemy in hit_enemies:
			return
		
		hit_enemies.append(enemy)
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func _spawn_new_enemies(position: Vector2) -> void:
	# Signal to spawn new enemies (handled by level manager)
	if get_tree().has_group("level_manager"):
		var level_manager = get_tree().get_first_node_in_group("level_manager")
		if level_manager and level_manager.has_method("spawn_enemies"):
			level_manager.spawn_enemies(position, 2)

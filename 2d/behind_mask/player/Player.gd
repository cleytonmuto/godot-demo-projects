extends CharacterBody2D

@export var speed := 200.0
@export var max_health := 50
@export var health := 50

signal health_changed(current: int, max_health: int)

@onready var mask_manager := $MaskManager
@onready var visual := $Visual
@onready var mask_base := $Visual/MaskBase
@onready var mask_top := $Visual/MaskTop
@onready var mask_chin := $Visual/MaskChin
@onready var brow := $Visual/Brow
@onready var nose_bridge := $Visual/NoseBridge
@onready var mask_base_shadow := $Visual/MaskBaseShadow
@onready var mask_top_shadow := $Visual/MaskTopShadow
@onready var sword := $Sword

var is_animating := false
var invulnerable := false
var invulnerability_duration := 1.0
var invulnerability_timer := 0.0

func _ready() -> void:
	# Apply stats from ExperienceManager (level-up bonuses)
	var exp_mgr := get_node_or_null("/root/ExperienceManager")
	if exp_mgr:
		speed = exp_mgr.get_speed()
		max_health = exp_mgr.get_max_health()
		health = max_health
		if sword:
			sword.damage = exp_mgr.get_sword_damage()
	mask_manager.mask_changed.connect(_on_mask_changed)
	_apply_mask_color(mask_manager.get_mask_color())
	health = max_health
	health_changed.emit(health, max_health)
	
	# Connect to bullet hits
	var hit_area := Area2D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 0
	hit_area.collision_mask = 8  # Enemy bullets layer
	var hit_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 16.0
	hit_shape.shape = circle_shape
	hit_area.add_child(hit_shape)
	add_child(hit_area)
	hit_area.body_entered.connect(_on_bullet_hit)

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	# Animate movement
	_animate_movement(delta)
	
	# Sword attack
	if Input.is_action_just_pressed("action"):
		if sword and not sword.is_swinging:
			sword.swing()
	
	# Update invulnerability
	if invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			invulnerable = false
			visual.modulate = Color.WHITE
		else:
			# Flash effect
			var flash := sin(invulnerability_timer * 20.0) * 0.5 + 0.5
			visual.modulate = Color(1.0, flash, flash, 1.0)
	
	if Input.is_action_just_pressed("restart"):
		die()

func _on_mask_changed(_mask: int) -> void:
	if is_animating:
		return
	is_animating = true
	
	var color: Color = mask_manager.get_mask_color()
	
	# Screen flash effect
	EffectManager.flash_screen(color, 0.15)
	
	# Flash white briefly
	var flash_tween := create_tween()
	flash_tween.tween_property(visual, "modulate", Color(2, 2, 2, 1), 0.05)
	flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	
	# Scale pop effect
	var scale_tween := create_tween()
	scale_tween.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.05)
	scale_tween.tween_property(visual, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Apply colors after brief delay
	await flash_tween.finished
	_apply_mask_color(color)
	is_animating = false

func _apply_mask_color(color: Color) -> void:
	# Color all mask parts
	mask_base.color = color
	mask_top.color = color
	mask_chin.color = color
	# Shadows use darker version
	var shadow_color := color.darkened(0.15)
	if mask_base_shadow:
		mask_base_shadow.color = shadow_color
	if mask_top_shadow:
		mask_top_shadow.color = shadow_color
	# Slightly darker shade for details
	var detail_color := color.darkened(0.1)
	brow.color = detail_color
	nose_bridge.color = detail_color
	# Make the visual slightly transparent for ghost mask
	visual.modulate.a = color.a

func take_damage(amount: int) -> void:
	if invulnerable:
		return
	
	health -= amount
	health = max(0, health)
	health_changed.emit(health, max_health)
	
	# Invulnerability period
	invulnerable = true
	invulnerability_timer = invulnerability_duration
	
	# Visual feedback
	var shake_tween := create_tween()
	shake_tween.tween_property(visual, "position:x", visual.position.x + 5, 0.05)
	shake_tween.tween_property(visual, "position:x", visual.position.x - 5, 0.05)
	shake_tween.tween_property(visual, "position:x", visual.position.x, 0.05)
	
	AudioManager.play_player_hurt()
	
	# Check for death immediately after health update
	if health <= 0:
		# Use call_deferred to ensure health is properly set
		call_deferred("die")

func _on_bullet_hit(body: Node2D) -> void:
	if body.is_in_group("enemy_bullets"):
		take_damage(body.damage)
		body.queue_free()

func _animate_movement(delta: float) -> void:
	# Subtle bobbing when moving
	if velocity.length() > 0:
		var bob_amount := sin(Engine.get_process_frames() * 0.15) * 1.5
		visual.position.y = bob_amount
		
		# Create dust particles when moving
		if randf() < 0.1:  # 10% chance per frame
			ParticleManager.create_dust(global_position, -velocity.normalized())
	else:
		visual.position.y = lerp(visual.position.y, 0.0, delta * 5.0)

func die() -> void:
	Game.restart_level()

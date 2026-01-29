extends CharacterBody2D
class_name BaseEnemy

@export var speed := 100.0
@export var chase_speed := 140.0
@export var flee_speed := 120.0
@export var patrol_distance := 64.0
@export var detection_radius := 180.0
@export var communication_radius := 250.0
@export var max_health := 20
@export var health := 2
@export var shoot_interval := 2.0
@export var shoot_range := 400.0
@export var knockback_force := 1200.0
@export var knockback_decay := 0.85
@export var knockback_duration := 0.2

## Patrol pattern: 0=horizontal, 1=vertical, 2=circular, 3=random
@export_enum("Horizontal", "Vertical", "Circular", "Random") var patrol_pattern := 0

enum State { PATROL, ALERT, CHASE, FLEE, INVESTIGATE }

var start_position: Vector2
var direction := 1
var current_state := State.PATROL
var player: CharacterBody2D
var mask_manager: Node

# Memory system
var last_seen_position: Vector2 = Vector2.ZERO
var has_memory := false
var memory_duration := 5.0
var memory_timer := 0.0

# Patrol pattern variables
var patrol_angle := 0.0
var random_target: Vector2 = Vector2.ZERO
var random_wait_timer := 0.0

# Communication
var alerted_by_ally := false

# Shooting
var shoot_timer := 0.0
var bullet_scene: PackedScene

# Knockback
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0
var is_knocked_back := false

@onready var visual := $Visual
@onready var detection_circle := $DetectionCircle
@onready var alert_indicator := $AlertIndicator
@onready var hit_area := $HitArea

func _ready() -> void:
	start_position = global_position
	random_target = start_position
	_draw_detection_circle()
	alert_indicator.visible = false
	add_to_group("enemies")
	health = max_health
	
	# Load bullet scene
	bullet_scene = preload("res://enemy/EnemyBullet.tscn")
	
	# Wait a frame to ensure player is ready
	await get_tree().process_frame
	_connect_to_player()

func _draw_detection_circle() -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := i * TAU / 32
		points.append(Vector2(cos(angle), sin(angle)) * detection_radius)
	detection_circle.polygon = points
	detection_circle.color = Color(1, 0.3, 0.3, 0.08)

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		_on_mask_changed(mask_manager.current_mask)
	
	# Connect hit area
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	# Update knockback timer
	if is_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
			knockback_velocity = Vector2.ZERO
	
	# Update memory timer
	if has_memory:
		memory_timer -= delta
		if memory_timer <= 0:
			has_memory = false
	
	# Update shoot timer
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		_try_shoot()
		shoot_timer = 0.0
	
	# Animate visual based on movement
	_animate_movement(delta)
	
	# Check mask states - GUARD (blue) is priority ignore, PREDATOR (red) causes flee
	var should_ignore: bool = mask_manager != null and not mask_manager.can_enemy_chase() and not mask_manager.should_enemy_flee()
	var should_flee: bool = mask_manager != null and mask_manager.should_enemy_flee()
	var can_chase: bool = mask_manager != null and mask_manager.can_enemy_chase()
	
	# Track player position only when not ignoring
	if not should_ignore:
		last_seen_position = player.global_position
		has_memory = true
		memory_timer = memory_duration
	
	# If knocked back, prioritize knockback movement over AI
	if is_knocked_back:
		# During knockback, reduce AI movement and let knockback dominate
		var ai_velocity := Vector2.ZERO
		match current_state:
			State.PATROL:
				_do_hunt(delta)
			State.ALERT, State.CHASE:
				_do_chase()
			State.FLEE:
				_do_flee()
			State.INVESTIGATE:
				_do_hunt(delta)
		
		# Blend AI movement with knockback (knockback is stronger)
		velocity = velocity * 0.3 + knockback_velocity
		knockback_velocity *= knockback_decay
		move_and_slide()
		if velocity.x != 0:
			visual.scale.x = sign(velocity.x)
		return
	
	# PRIORITY: If player wears Guard mask, wander randomly (ignore player)
	if should_ignore:
		_do_wander(delta)
		_update_detection_visual(false)
		alert_indicator.visible = false
		current_state = State.PATROL
		move_and_slide()
		if velocity.x != 0:
			visual.scale.x = sign(velocity.x)
		return
	
	match current_state:
		State.PATROL:
			# Hunt toward player
			_do_hunt(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			elif can_chase:
				_enter_chase_state_fast()
		
		State.ALERT:
			_do_chase()
			_update_detection_visual(true)
		
		State.CHASE:
			_do_chase()
			_update_detection_visual(true)
			if should_flee:
				_enter_flee_state()
		
		State.FLEE:
			_do_flee()
			_update_detection_visual(false, true)
			if not should_flee:
				if can_chase:
					_enter_chase_state_fast()
				else:
					_enter_patrol_state()
		
		State.INVESTIGATE:
			_do_hunt(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			elif can_chase:
				_enter_chase_state_fast()
	
	move_and_slide()
	
	# Flip visual based on movement direction
	if velocity.x != 0:
		visual.scale.x = sign(velocity.x)

func _do_patrol(delta: float) -> void:
	# Random wandering when not chasing
	_do_wander(delta)

func _do_wander(delta: float) -> void:
	# Move randomly around the area
	random_wait_timer -= delta
	if random_wait_timer <= 0 or global_position.distance_to(random_target) < 15:
		# Pick new random target
		random_target = start_position + Vector2(
			randf_range(-patrol_distance * 2, patrol_distance * 2),
			randf_range(-patrol_distance * 2, patrol_distance * 2)
		)
		random_wait_timer = randf_range(1.5, 3.0)
	velocity = (random_target - global_position).normalized() * speed * 0.6

func _do_hunt(_delta: float) -> void:
	# Move toward player at patrol speed
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed

func _do_chase() -> void:
	var target_pos: Vector2
	
	# Chase decoy if active, otherwise chase player
	if mask_manager and mask_manager.has_active_decoy:
		target_pos = mask_manager.decoy_position
	else:
		target_pos = player.global_position
	
	var dir := (target_pos - global_position).normalized()
	velocity = dir * chase_speed

func _do_flee() -> void:
	var dir := (global_position - player.global_position).normalized()
	velocity = dir * flee_speed

func _do_investigate() -> void:
	if not has_memory:
		_enter_patrol_state()
		return
	
	var dir := (last_seen_position - global_position).normalized()
	velocity = dir * speed * 0.8
	
	# Reached investigation point
	if global_position.distance_to(last_seen_position) < 20:
		has_memory = false
		# Look around briefly then return to patrol
		alert_indicator.text = "?"
		await get_tree().create_timer(1.5).timeout
		if current_state == State.INVESTIGATE:
			_enter_patrol_state()

func _enter_investigate_state() -> void:
	if not has_memory:
		_enter_patrol_state()
		return
	current_state = State.INVESTIGATE
	alert_indicator.visible = true
	alert_indicator.text = "?"
	alert_indicator.modulate = Color.ORANGE

func _enter_patrol_state() -> void:
	current_state = State.PATROL
	alert_indicator.visible = false

func _enter_alert_state() -> void:
	# Redirect to fast chase
	_enter_chase_state_fast()

func _enter_chase_state_fast() -> void:
	current_state = State.CHASE
	alert_indicator.visible = true
	alert_indicator.text = "!"
	alert_indicator.modulate = Color.RED
	
	# Play alert sound (only if not already chasing)
	AudioManager.play_enemy_alert()

func _enter_flee_state() -> void:
	current_state = State.FLEE
	alert_indicator.visible = true
	alert_indicator.text = "!!"
	alert_indicator.modulate = Color.YELLOW
	
	# Play flee sound
	AudioManager.play_enemy_flee()

func _update_detection_visual(is_aggressive: bool, is_fleeing: bool = false) -> void:
	if is_fleeing:
		detection_circle.color = Color(1, 1, 0.3, 0.12)
		visual.modulate = Color(1.0, 0.8, 0.8)
	elif is_aggressive:
		detection_circle.color = Color(1, 0.3, 0.3, 0.15)
		visual.modulate = Color(1.2, 0.9, 0.9)
	else:
		detection_circle.color = Color(1, 0.3, 0.3, 0.08)
		visual.modulate = Color.WHITE

func _on_mask_changed(_mask: int) -> void:
	if not mask_manager:
		return
	
	# PRIORITY: Guard mask (blue) = wander randomly, ignore player
	if not mask_manager.can_enemy_chase() and not mask_manager.should_enemy_flee():
		alert_indicator.visible = false
		current_state = State.PATROL
		# Reset random target to start wandering
		random_wait_timer = 0
		return
	
	if mask_manager.should_enemy_flee():
		_enter_flee_state()
	elif mask_manager.can_enemy_chase():
		_enter_chase_state_fast()

func _try_shoot() -> void:
	if not is_instance_valid(player):
		return
	
	# Only shoot if player is in range and we can see them
	var distance := global_position.distance_to(player.global_position)
	if distance > shoot_range:
		return
	
	# Check if we should shoot (not ignoring player, not fleeing)
	var should_ignore: bool = mask_manager != null and not mask_manager.can_enemy_chase() and not mask_manager.should_enemy_flee()
	var should_flee: bool = mask_manager != null and mask_manager.should_enemy_flee()
	
	if should_ignore or should_flee:
		return
	
	# Shoot at player
	_shoot_at(player.global_position)

func _shoot_at(target_pos: Vector2) -> void:
	if not bullet_scene:
		return
	
	var bullet := bullet_scene.instantiate() as EnemyBullet
	if not bullet:
		return
	
	get_tree().current_scene.add_child(bullet)
	bullet.setup(global_position, target_pos)
	AudioManager.play_enemy_shoot()

func take_damage(amount: int, hit_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	
	# Apply animated knockback if hit position is provided
	if hit_position != Vector2.ZERO:
		var knockback_direction := (global_position - hit_position).normalized()
		# Ensure we have a valid direction
		if knockback_direction.length() < 0.1:
			# Fallback: push away from player if hit position is too close
			if is_instance_valid(player):
				knockback_direction = (global_position - player.global_position).normalized()
			else:
				knockback_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		# Set strong initial knockback
		knockback_velocity = knockback_direction * knockback_force
		is_knocked_back = true
		knockback_timer = knockback_duration
		
		# Visual knockback animation - tilt enemy slightly
		var tilt_tween := create_tween()
		var tilt_amount := knockback_direction.x * 0.2  # Tilt based on knockback direction
		visual.rotation = tilt_amount
		tilt_tween.tween_property(visual, "rotation", 0.0, knockback_duration)
		
		# Scale animation - enemy "shrinks" slightly when hit
		var scale_tween := create_tween()
		visual.scale = Vector2(0.9, 0.9)
		scale_tween.tween_property(visual, "scale", Vector2(1.0, 1.0), knockback_duration * 0.5)
	
	# Visual feedback
	var flash_tween := create_tween()
	flash_tween.tween_property(visual, "modulate", Color(2, 0.5, 0.5, 1), 0.1)
	flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	
	# Damage number
	DamageNumber.create(global_position, amount)
	
	# Hit sparks
	ParticleManager.create_hit_sparks(global_position, Color(1, 0.8, 0.2))
	
	# Camera shake
	Game.shake_camera(0.05, 0.1)
	
	if health <= 0:
		_die()

func _die() -> void:
	# Add score
	var enemy_type := "normal"
	if self is DetectorEnemy:
		enemy_type = "detector"
	elif self is HunterEnemy:
		enemy_type = "hunter"
	elif self is MimicEnemy:
		enemy_type = "mimic"
	
	ScoreManager.add_kill_score(enemy_type)
	ExperienceManager.add_exp(max_health)
	# Slow-mo effect on kill
	EffectManager.slow_mo(0.15, 0.4)
	
	# Explosion effect
	ParticleManager.create_explosion(global_position, 1.0, Color(1, 0.3, 0.1))
	
	# Spawn new enemies before dying
	_spawn_new_enemies()
	queue_free()

func _spawn_new_enemies() -> void:
	# Signal to spawn new enemies (handled by level manager)
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager and level_manager.has_method("spawn_enemies"):
		level_manager.spawn_enemies(global_position, 2)

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if mask_manager and mask_manager.can_collide_with_enemy():
			body.take_damage(10)  # Contact damage

# Communication system - alert nearby enemies
func _alert_nearby_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == self:
			continue
		if enemy is BaseEnemy:
			var dist := global_position.distance_to(enemy.global_position)
			if dist < communication_radius:
				enemy.receive_alert(last_seen_position)

func receive_alert(position: Vector2) -> void:
	if current_state == State.PATROL:
		last_seen_position = position
		has_memory = true
		memory_timer = memory_duration
		alerted_by_ally = true

func _animate_movement(delta: float) -> void:
	# Subtle bobbing animation
	if velocity.length() > 0:
		var bob_amount := sin(Engine.get_process_frames() * 0.2) * 2.0
		visual.position.y = bob_amount
	else:
		visual.position.y = lerp(visual.position.y, 0.0, delta * 5.0)

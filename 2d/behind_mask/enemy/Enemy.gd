extends CharacterBody2D

@export var speed := 100.0
@export var chase_speed := 140.0
@export var flee_speed := 120.0
@export var patrol_distance := 64.0
@export var detection_radius := 180.0

enum State { PATROL, ALERT, CHASE, FLEE }

var start_position: Vector2
var direction := 1
var current_state := State.PATROL
var player: CharacterBody2D
var mask_manager: Node

@onready var visual := $Visual
@onready var detection_circle := $DetectionCircle
@onready var alert_indicator := $AlertIndicator
@onready var hit_area := $HitArea

func _ready() -> void:
	start_position = global_position
	_draw_detection_circle()
	alert_indicator.visible = false
	
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
	
	var distance := global_position.distance_to(player.global_position)
	var in_range := distance < detection_radius
	
	match current_state:
		State.PATROL:
			_do_patrol()
			_update_detection_visual(false)
			if in_range:
				if mask_manager and mask_manager.should_enemy_flee():
					_enter_flee_state()
				elif mask_manager and mask_manager.can_enemy_chase():
					_enter_alert_state()
		
		State.ALERT:
			velocity = Vector2.ZERO
			_update_detection_visual(true)
		
		State.CHASE:
			_do_chase()
			_update_detection_visual(true)
			if mask_manager:
				if mask_manager.should_enemy_flee():
					_enter_flee_state()
				elif not mask_manager.can_enemy_chase():
					_enter_patrol_state()
		
		State.FLEE:
			_do_flee()
			_update_detection_visual(false, true)
			if mask_manager and not mask_manager.should_enemy_flee():
				if mask_manager.can_enemy_chase() and in_range:
					_enter_alert_state()
				else:
					_enter_patrol_state()
	
	move_and_slide()
	
	# Flip visual based on movement direction
	if velocity.x != 0:
		visual.scale.x = sign(velocity.x)

func _do_patrol() -> void:
	velocity.x = direction * speed
	velocity.y = 0
	if abs(global_position.x - start_position.x) > patrol_distance:
		direction *= -1

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

func _enter_patrol_state() -> void:
	current_state = State.PATROL
	alert_indicator.visible = false

func _enter_alert_state() -> void:
	current_state = State.ALERT
	alert_indicator.visible = true
	alert_indicator.text = "!"
	alert_indicator.modulate = Color.RED
	
	# Play alert sound
	AudioManager.play_enemy_alert()
	
	# Brief pause before chasing
	var alert_tween := create_tween()
	alert_tween.tween_property(alert_indicator, "scale", Vector2(1.5, 1.5), 0.15)
	alert_tween.tween_property(alert_indicator, "scale", Vector2.ONE, 0.15)
	
	await get_tree().create_timer(0.4).timeout
	
	# Check if we should still chase after the pause
	if mask_manager and mask_manager.can_enemy_chase() and not mask_manager.should_enemy_flee():
		current_state = State.CHASE
	else:
		_enter_patrol_state()

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
	
	var distance := global_position.distance_to(player.global_position)
	var in_range := distance < detection_radius
	
	if mask_manager.should_enemy_flee():
		if current_state != State.FLEE:
			_enter_flee_state()
	elif mask_manager.can_enemy_chase():
		if current_state == State.FLEE or current_state == State.PATROL:
			if in_range:
				_enter_alert_state()
	else:
		# Can't chase anymore (Guard mask)
		_enter_patrol_state()

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if mask_manager and mask_manager.can_collide_with_enemy():
			body.die()

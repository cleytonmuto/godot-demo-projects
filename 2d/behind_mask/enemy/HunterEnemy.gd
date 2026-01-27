extends BaseEnemy
class_name HunterEnemy

## Hunter Enemy - Can see through Guard mask after 2 seconds of close proximity.
## Player must keep moving when using Guard mask near Hunters.
## Visual: Dark green color

@export var detection_time := 2.0  # Time to see through Guard mask

var guard_exposure_timer := 0.0
var is_detecting_guard := false

func _ready() -> void:
	super._ready()
	# Dark green color for hunter
	$Visual/Body.color = Color(0.2, 0.5, 0.2, 1)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	# Update memory timer
	if has_memory:
		memory_timer -= delta
		if memory_timer <= 0:
			has_memory = false
	
	var distance := global_position.distance_to(player.global_position)
	var in_range := distance < detection_radius
	var close_range := distance < detection_radius * 0.5  # Within half detection radius
	
	# Hunter detection logic
	var can_chase := false
	if mask_manager:
		if mask_manager.should_enemy_flee():
			can_chase = false  # Still respects Predator
		elif mask_manager.current_mask == mask_manager.Mask.GUARD:
			# Slowly detect Guard mask at close range
			if close_range:
				guard_exposure_timer += delta
				is_detecting_guard = true
				if guard_exposure_timer >= detection_time:
					can_chase = true
			else:
				guard_exposure_timer = maxf(0, guard_exposure_timer - delta * 0.5)
				is_detecting_guard = guard_exposure_timer > 0
		else:
			guard_exposure_timer = 0
			is_detecting_guard = false
			can_chase = mask_manager.can_enemy_chase() and in_range
	
	# Remember player position when visible
	if can_chase:
		last_seen_position = player.global_position
		has_memory = true
		memory_timer = memory_duration
	
	# Update visual indicator for detection progress
	if is_detecting_guard and current_state == State.PATROL:
		alert_indicator.visible = true
		alert_indicator.text = "..."
		alert_indicator.modulate = Color.YELLOW.lerp(Color.RED, guard_exposure_timer / detection_time)
	
	match current_state:
		State.PATROL:
			_do_patrol(delta)
			_update_detection_visual(false)
			if mask_manager and mask_manager.should_enemy_flee() and in_range:
				_enter_flee_state()
			elif can_chase:
				_enter_alert_state()
				_alert_nearby_enemies()
			elif alerted_by_ally:
				alerted_by_ally = false
				_enter_investigate_state()
		
		State.ALERT:
			velocity = Vector2.ZERO
			_update_detection_visual(true)
		
		State.CHASE:
			_do_chase()
			_update_detection_visual(true)
			if mask_manager:
				if mask_manager.should_enemy_flee():
					_enter_flee_state()
				elif not can_chase and not (mask_manager.current_mask == mask_manager.Mask.GUARD and close_range):
					if has_memory:
						_enter_investigate_state()
					else:
						_enter_patrol_state()
		
		State.FLEE:
			_do_flee()
			_update_detection_visual(false, true)
			if mask_manager and not mask_manager.should_enemy_flee():
				if can_chase:
					_enter_alert_state()
				else:
					_enter_patrol_state()
		
		State.INVESTIGATE:
			_do_investigate()
			_update_detection_visual(false)
			if mask_manager and mask_manager.should_enemy_flee() and in_range:
				_enter_flee_state()
			elif can_chase:
				_enter_alert_state()
	
	move_and_slide()
	
	if velocity.x != 0:
		visual.scale.x = sign(velocity.x)

func _enter_patrol_state() -> void:
	super._enter_patrol_state()
	guard_exposure_timer = 0
	is_detecting_guard = false

func _update_detection_visual(is_aggressive: bool, is_fleeing: bool = false) -> void:
	if is_fleeing:
		detection_circle.color = Color(1, 1, 0.3, 0.12)
		visual.modulate = Color(0.8, 1.0, 0.8)
	elif is_aggressive:
		detection_circle.color = Color(0.2, 0.5, 0.2, 0.15)
		visual.modulate = Color(0.9, 1.2, 0.9)
	elif is_detecting_guard:
		detection_circle.color = Color(0.5, 0.5, 0.2, 0.12)
		visual.modulate = Color(1.0, 1.0, 0.8)
	else:
		detection_circle.color = Color(0.2, 0.5, 0.2, 0.08)
		visual.modulate = Color.WHITE

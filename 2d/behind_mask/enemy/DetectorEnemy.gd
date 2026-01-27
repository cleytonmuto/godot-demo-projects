extends BaseEnemy
class_name DetectorEnemy

## Detector Enemy - Can see through all masks EXCEPT Ghost.
## Forces players to use Ghost mask in certain areas.
## Visual: Purple color with an "eye" symbol

func _ready() -> void:
	super._ready()
	# Purple color for detector
	$Visual/Body.color = Color(0.6, 0.2, 0.8, 1)

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
	
	# Detector can see through all masks except Ghost
	var can_see_player := false
	if mask_manager:
		# Can only hide from detector with Ghost mask
		can_see_player = in_range and mask_manager.current_mask != mask_manager.Mask.GHOST
	
	if can_see_player:
		last_seen_position = player.global_position
		has_memory = true
		memory_timer = memory_duration
	
	match current_state:
		State.PATROL:
			_do_patrol(delta)
			_update_detection_visual(false)
			if can_see_player:
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
			if not can_see_player:
				if has_memory:
					_enter_investigate_state()
				else:
					_enter_patrol_state()
		
		State.FLEE:
			# Detector doesn't flee - it's fearless
			_enter_patrol_state()
		
		State.INVESTIGATE:
			_do_investigate()
			_update_detection_visual(false)
			if can_see_player:
				_enter_alert_state()
	
	move_and_slide()
	
	if velocity.x != 0:
		visual.scale.x = sign(velocity.x)

func _update_detection_visual(is_aggressive: bool, _is_fleeing: bool = false) -> void:
	if is_aggressive:
		detection_circle.color = Color(0.6, 0.2, 0.8, 0.15)
		visual.modulate = Color(1.2, 0.9, 1.2)
	else:
		detection_circle.color = Color(0.6, 0.2, 0.8, 0.08)
		visual.modulate = Color.WHITE

func _on_mask_changed(_mask: int) -> void:
	# Detector reacts immediately if player is visible
	if not mask_manager:
		return
	
	var distance := global_position.distance_to(player.global_position)
	var in_range := distance < detection_radius
	var can_see: bool = in_range and mask_manager.current_mask != mask_manager.Mask.GHOST
	
	if can_see and current_state == State.PATROL:
		_enter_alert_state()
	elif not can_see and current_state == State.CHASE:
		if has_memory:
			_enter_investigate_state()
		else:
			_enter_patrol_state()

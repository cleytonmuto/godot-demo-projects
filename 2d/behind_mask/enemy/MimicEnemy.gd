extends BaseEnemy
class_name MimicEnemy

## Mimic Enemy - Copies the player's current mask color.
## Behavior is OPPOSITE of normal: chases when you'd expect safety.
## - When player wears Guard: Mimic chases (sees through disguise)
## - When player wears Neutral: Mimic ignores (confused by lack of mask)
## Visual: Shifts colors to match player

var base_color := Color(0.5, 0.5, 0.5)

func _ready() -> void:
	super._ready()
	base_color = Color(0.5, 0.5, 0.5)
	$Visual/Body.color = base_color

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
	
	# Mimic has INVERTED behavior
	var should_chase := false
	var should_flee := false
	if mask_manager:
		match mask_manager.current_mask:
			mask_manager.Mask.NEUTRAL:
				should_chase = false  # Ignores neutral (opposite of normal)
			mask_manager.Mask.GUARD:
				should_chase = in_range  # Chases guard (opposite of normal)
			mask_manager.Mask.GHOST:
				should_chase = in_range  # Can see ghosts (opposite of normal)
			mask_manager.Mask.PREDATOR:
				should_chase = in_range  # Not afraid (opposite of normal)
			mask_manager.Mask.DECOY:
				should_flee = in_range  # Afraid of decoy? (weird but opposite)
	
	if should_chase:
		last_seen_position = player.global_position
		has_memory = true
		memory_timer = memory_duration
	
	match current_state:
		State.PATROL:
			_do_patrol(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			elif should_chase:
				_enter_alert_state()
			elif alerted_by_ally:
				alerted_by_ally = false
				_enter_investigate_state()
		
		State.ALERT:
			velocity = Vector2.ZERO
			_update_detection_visual(true)
		
		State.CHASE:
			_do_chase()
			_update_detection_visual(true)
			if should_flee:
				_enter_flee_state()
			elif not should_chase:
				if has_memory:
					_enter_investigate_state()
				else:
					_enter_patrol_state()
		
		State.FLEE:
			_do_flee()
			_update_detection_visual(false, true)
			if not should_flee:
				if should_chase:
					_enter_alert_state()
				else:
					_enter_patrol_state()
		
		State.INVESTIGATE:
			_do_investigate()
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			elif should_chase:
				_enter_alert_state()
	
	move_and_slide()
	
	if velocity.x != 0:
		visual.scale.x = sign(velocity.x)

func _on_mask_changed(mask: int) -> void:
	if not mask_manager:
		return
	
	# Mimic copies player's mask color
	var player_color: Color = mask_manager.get_mask_color()
	var tween := create_tween()
	tween.tween_property($Visual/Body, "color", player_color, 0.3)
	
	# Also update behavior
	var distance := global_position.distance_to(player.global_position)
	var in_range := distance < detection_radius
	
	# Inverted logic
	var should_chase := false
	match mask_manager.current_mask:
		mask_manager.Mask.NEUTRAL:
			should_chase = false
		mask_manager.Mask.GUARD, mask_manager.Mask.GHOST, mask_manager.Mask.PREDATOR:
			should_chase = in_range
		mask_manager.Mask.DECOY:
			if current_state != State.FLEE:
				_enter_flee_state()
			return
	
	if should_chase and current_state == State.PATROL:
		_enter_alert_state()
	elif not should_chase and current_state == State.CHASE:
		if has_memory:
			_enter_investigate_state()
		else:
			_enter_patrol_state()

func _update_detection_visual(is_aggressive: bool, is_fleeing: bool = false) -> void:
	# Mimic detection circle matches current mask color
	var mask_color := Color.GRAY
	if mask_manager:
		mask_color = mask_manager.get_mask_color()
	
	if is_fleeing:
		detection_circle.color = Color(mask_color.r, mask_color.g, mask_color.b, 0.12)
	elif is_aggressive:
		detection_circle.color = Color(mask_color.r, mask_color.g, mask_color.b, 0.18)
	else:
		detection_circle.color = Color(mask_color.r, mask_color.g, mask_color.b, 0.08)

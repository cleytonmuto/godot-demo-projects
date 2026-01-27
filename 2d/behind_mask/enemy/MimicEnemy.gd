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
	
	# Mimic has INVERTED behavior
	var should_chase := false
	var should_flee := false
	var should_ignore := false
	if mask_manager:
		match mask_manager.current_mask:
			mask_manager.Mask.NEUTRAL:
				should_ignore = true  # Ignores neutral (opposite of normal)
			mask_manager.Mask.GUARD:
				should_chase = true  # Chases guard (opposite of normal)
			mask_manager.Mask.GHOST:
				should_chase = true  # Can see ghosts (opposite of normal)
			mask_manager.Mask.PREDATOR:
				should_chase = true  # Not afraid (opposite of normal)
			mask_manager.Mask.DECOY:
				should_flee = true  # Afraid of decoy (opposite)
	
	# If Neutral mask (inverted ignore), wander randomly
	if should_ignore:
		_do_wander(delta)
		_update_detection_visual(false)
		alert_indicator.visible = false
		current_state = State.PATROL
		move_and_slide()
		if velocity.x != 0:
			visual.scale.x = sign(velocity.x)
		return
	
	# Track player when active
	last_seen_position = player.global_position
	has_memory = true
	memory_timer = memory_duration
	
	match current_state:
		State.PATROL:
			_do_hunt(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			elif should_chase:
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
				if should_chase:
					_enter_chase_state_fast()
				else:
					_enter_patrol_state()
		
		State.INVESTIGATE:
			_do_hunt(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			elif should_chase:
				_enter_chase_state_fast()
	
	move_and_slide()
	
	if velocity.x != 0:
		visual.scale.x = sign(velocity.x)

func _on_mask_changed(_mask: int) -> void:
	if not mask_manager:
		return
	
	# Mimic copies player's mask color
	var player_color: Color = mask_manager.get_mask_color()
	var tween := create_tween()
	tween.tween_property($Visual/Body, "color", player_color, 0.3)
	
	# Inverted logic - react immediately
	match mask_manager.current_mask:
		mask_manager.Mask.NEUTRAL:
			# Wander when player wears Neutral (inverted ignore)
			alert_indicator.visible = false
			current_state = State.PATROL
			random_wait_timer = 0
		mask_manager.Mask.GUARD, mask_manager.Mask.GHOST, mask_manager.Mask.PREDATOR:
			_enter_chase_state_fast()
		mask_manager.Mask.DECOY:
			_enter_flee_state()

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

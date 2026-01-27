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
	
	# Detector can see through Guard mask, but NOT Ghost
	# Still flees from Predator (red)
	var is_ghost: bool = mask_manager != null and mask_manager.current_mask == mask_manager.Mask.GHOST
	var should_flee: bool = mask_manager != null and mask_manager.should_enemy_flee()
	
	# If Ghost mask, wander randomly (can't see player)
	if is_ghost:
		_do_wander(delta)
		_update_detection_visual(false)
		alert_indicator.visible = false
		current_state = State.PATROL
		move_and_slide()
		if velocity.x != 0:
			visual.scale.x = sign(velocity.x)
		return
	
	# Track player
	last_seen_position = player.global_position
	has_memory = true
	memory_timer = memory_duration
	
	match current_state:
		State.PATROL:
			_do_hunt(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			else:
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
				_enter_chase_state_fast()
		
		State.INVESTIGATE:
			_do_hunt(delta)
			_update_detection_visual(false)
			if should_flee:
				_enter_flee_state()
			else:
				_enter_chase_state_fast()
	
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
	if not mask_manager:
		return
	
	# Ghost = can't see, wander
	if mask_manager.current_mask == mask_manager.Mask.GHOST:
		alert_indicator.visible = false
		current_state = State.PATROL
		random_wait_timer = 0
		return
	
	# Predator = flee
	if mask_manager.should_enemy_flee():
		_enter_flee_state()
	else:
		# Can see through Guard, so chase
		_enter_chase_state_fast()

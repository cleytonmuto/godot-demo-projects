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
	
	var distance := global_position.distance_to(player.global_position)
	var close_range := distance < detection_radius * 0.6
	
	# Priority checks
	var should_flee: bool = mask_manager != null and mask_manager.should_enemy_flee()
	var is_guard: bool = mask_manager != null and mask_manager.current_mask == mask_manager.Mask.GUARD
	var is_ghost: bool = mask_manager != null and mask_manager.current_mask == mask_manager.Mask.GHOST
	
	# Hunter detection logic for Guard mask
	var can_chase := false
	if should_flee:
		can_chase = false
		guard_exposure_timer = 0
		is_detecting_guard = false
	elif is_guard:
		# Detect Guard mask - faster at close range
		if close_range:
			guard_exposure_timer += delta * 1.5
		else:
			guard_exposure_timer += delta * 0.3
		is_detecting_guard = guard_exposure_timer > 0.3
		can_chase = guard_exposure_timer >= detection_time
	elif is_ghost:
		# Ghost mask = can't see at all
		guard_exposure_timer = 0
		is_detecting_guard = false
		can_chase = false
	else:
		# Normal masks (Neutral, Decoy)
		guard_exposure_timer = 0
		is_detecting_guard = false
		can_chase = mask_manager and mask_manager.can_enemy_chase()
	
	# Update visual indicator for detection progress
	if is_detecting_guard and not can_chase:
		alert_indicator.visible = true
		alert_indicator.text = "..."
		alert_indicator.modulate = Color.YELLOW.lerp(Color.RED, guard_exposure_timer / detection_time)
	
	# If Guard mask and not yet detected, wander while detecting
	if is_guard and not can_chase:
		_do_wander(delta)
		_update_detection_visual(false)
		move_and_slide()
		if velocity.x != 0:
			visual.scale.x = sign(velocity.x)
		return
	
	# If Ghost mask, wander randomly
	if is_ghost:
		_do_wander(delta)
		alert_indicator.visible = false
		_update_detection_visual(false)
		current_state = State.PATROL
		move_and_slide()
		if velocity.x != 0:
			visual.scale.x = sign(velocity.x)
		return
	
	# Track player when can chase
	if can_chase or should_flee:
		last_seen_position = player.global_position
		has_memory = true
		memory_timer = memory_duration
	
	match current_state:
		State.PATROL:
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

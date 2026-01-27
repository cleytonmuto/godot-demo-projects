extends Node

signal mask_changed(new_mask: int)
signal cooldown_changed(remaining: float)
signal charges_changed(mask: int, remaining: int)
signal detection_changed(level: float)
signal noise_made(position: Vector2, radius: float)

enum Mask {
	NEUTRAL,
	GUARD,
	GHOST,
	PREDATOR,
	DECOY
}

const MASK_COLORS := {
	Mask.NEUTRAL: Color.WHITE,
	Mask.GUARD: Color(0.4, 0.6, 1.0),
	Mask.GHOST: Color(0.7, 0.7, 0.7, 0.5),
	Mask.PREDATOR: Color(1.0, 0.3, 0.3),
	Mask.DECOY: Color(1.0, 0.9, 0.3),
}

const MASK_NAMES := {
	Mask.NEUTRAL: "NEUTRAL",
	Mask.GUARD: "GUARD",
	Mask.GHOST: "GHOST",
	Mask.PREDATOR: "PREDATOR",
	Mask.DECOY: "DECOY",
}

const MASK_HINTS := {
	Mask.NEUTRAL: "Enemies will chase you!",
	Mask.GUARD: "Enemies ignore you",
	Mask.GHOST: "Pass through enemies",
	Mask.PREDATOR: "Enemies flee from you!",
	Mask.DECOY: "Leave a decoy when switching",
}

# Per-mask cooldowns (in seconds)
const MASK_COOLDOWNS := {
	Mask.NEUTRAL: 0.5,
	Mask.GUARD: 2.0,
	Mask.GHOST: 1.0,
	Mask.PREDATOR: 2.5,
	Mask.DECOY: 1.5,
}

# Per-mask charges (-1 = unlimited)
const MASK_MAX_CHARGES := {
	Mask.NEUTRAL: -1,  # Unlimited
	Mask.GUARD: 5,
	Mask.GHOST: 4,
	Mask.PREDATOR: 3,
	Mask.DECOY: 3,
}

# Noise radius when switching masks
const MASK_NOISE_RADIUS := {
	Mask.NEUTRAL: 0.0,
	Mask.GUARD: 50.0,
	Mask.GHOST: 30.0,
	Mask.PREDATOR: 100.0,  # Loud transformation
	Mask.DECOY: 80.0,
}

var current_mask: Mask = Mask.NEUTRAL
var current_cooldown := 0.0
var decoy_position: Vector2 = Vector2.ZERO
var has_active_decoy := false

# Mask charges tracking
var mask_charges := {}

# Detection meter (0.0 to 1.0)
var detection_level := 0.0
var detection_decay_rate := 0.15  # Per second when not detected
var detection_fill_rate := 0.25  # Per second when in enemy range
var is_being_detected := false

# Stats tracking
var total_mask_switches := 0

func _ready() -> void:
	_reset_charges()

func _reset_charges() -> void:
	for mask in Mask.values():
		mask_charges[mask] = MASK_MAX_CHARGES.get(mask, -1)

func _process(delta: float) -> void:
	# Cooldown timer
	if current_cooldown > 0:
		current_cooldown -= delta
		cooldown_changed.emit(current_cooldown)
		if current_cooldown <= 0:
			current_cooldown = 0
			cooldown_changed.emit(0)
			AudioManager.play_cooldown_ready()
	
	# Detection meter decay
	if not is_being_detected and detection_level > 0:
		detection_level = maxf(0, detection_level - detection_decay_rate * delta)
		detection_changed.emit(detection_level)

func add_detection(amount: float) -> void:
	is_being_detected = true
	detection_level = minf(1.0, detection_level + amount)
	detection_changed.emit(detection_level)
	
	# Full detection = instant alert!
	if detection_level >= 1.0:
		# Force player to neutral and alert all enemies
		if current_mask != Mask.NEUTRAL:
			current_mask = Mask.NEUTRAL
			mask_changed.emit(current_mask)
		detection_level = 0.5  # Reset partially
	
	is_being_detected = false

func cycle_mask() -> void:
	if current_cooldown > 0:
		return  # Can't switch yet
	
	var previous_mask := current_mask
	var next_mask := ((current_mask as int) + 1) % Mask.size() as Mask
	
	# Skip masks with no charges remaining
	var attempts := 0
	while attempts < Mask.size():
		var charges: int = mask_charges.get(next_mask, -1)
		if charges == -1 or charges > 0:
			break
		next_mask = ((next_mask as int) + 1) % Mask.size() as Mask
		attempts += 1
	
	if attempts >= Mask.size():
		return  # No masks available!
	
	current_mask = next_mask
	
	# Use a charge (if not unlimited)
	var charges: int = mask_charges.get(current_mask, -1)
	if charges > 0:
		mask_charges[current_mask] = charges - 1
		charges_changed.emit(current_mask, mask_charges[current_mask])
	
	# Set cooldown based on the mask we switched TO
	current_cooldown = MASK_COOLDOWNS.get(current_mask, 1.0)
	
	# Track stats
	total_mask_switches += 1
	
	# Play mask switch sound
	AudioManager.play_mask_switch()
	
	# Make noise (enemies nearby may hear)
	var noise_radius: float = MASK_NOISE_RADIUS.get(current_mask, 0.0)
	if noise_radius > 0:
		noise_made.emit(get_parent().global_position, noise_radius)
	
	# If switching FROM decoy mask, record position for enemies to chase
	if previous_mask == Mask.DECOY:
		decoy_position = get_parent().global_position
		has_active_decoy = true
		get_tree().create_timer(3.0).timeout.connect(_clear_decoy)
	
	mask_changed.emit(current_mask)

func _clear_decoy() -> void:
	has_active_decoy = false

func can_switch() -> bool:
	if current_cooldown > 0:
		return false
	# Check if any mask has charges
	for mask in Mask.values():
		if mask == current_mask:
			continue
		var charges: int = mask_charges.get(mask, -1)
		if charges == -1 or charges > 0:
			return true
	return false

func get_charges(mask: Mask) -> int:
	return mask_charges.get(mask, -1)

func get_max_charges(mask: Mask) -> int:
	return MASK_MAX_CHARGES.get(mask, -1)

func get_cooldown_time() -> float:
	return MASK_COOLDOWNS.get(current_mask, 1.0)

func can_enemy_chase() -> bool:
	return current_mask == Mask.NEUTRAL or current_mask == Mask.DECOY

func can_collide_with_enemy() -> bool:
	return current_mask != Mask.GHOST

func should_enemy_flee() -> bool:
	return current_mask == Mask.PREDATOR

func get_mask_color() -> Color:
	return MASK_COLORS.get(current_mask, Color.WHITE)

func get_mask_name() -> String:
	return MASK_NAMES.get(current_mask, "UNKNOWN")

func get_mask_hint() -> String:
	return MASK_HINTS.get(current_mask, "")

func get_all_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for mask in Mask.values():
		colors.append(MASK_COLORS.get(mask, Color.WHITE))
	return colors

func get_mask_count() -> int:
	return Mask.size()

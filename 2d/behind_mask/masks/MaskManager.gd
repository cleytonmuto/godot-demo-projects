extends Node

signal mask_changed(new_mask: int)
signal cooldown_changed(remaining: float)

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

var current_mask: Mask = Mask.NEUTRAL
var cooldown_time := 1.0
var current_cooldown := 0.0
var decoy_position: Vector2 = Vector2.ZERO
var has_active_decoy := false

func _process(delta: float) -> void:
	if current_cooldown > 0:
		var was_on_cooldown := current_cooldown > 0
		current_cooldown -= delta
		cooldown_changed.emit(current_cooldown)
		if current_cooldown <= 0:
			current_cooldown = 0
			cooldown_changed.emit(0)
			if was_on_cooldown:
				AudioManager.play_cooldown_ready()

func cycle_mask() -> void:
	if current_cooldown > 0:
		return  # Can't switch yet
	
	var previous_mask := current_mask
	current_mask = ((current_mask as int) + 1) % Mask.size() as Mask
	current_cooldown = cooldown_time
	
	# Play mask switch sound
	AudioManager.play_mask_switch()
	
	# If switching FROM decoy mask, record position for enemies to chase
	if previous_mask == Mask.DECOY:
		decoy_position = get_parent().global_position
		has_active_decoy = true
		# Decoy expires after 3 seconds
		get_tree().create_timer(3.0).timeout.connect(_clear_decoy)
	
	mask_changed.emit(current_mask)

func _clear_decoy() -> void:
	has_active_decoy = false

func can_switch() -> bool:
	return current_cooldown <= 0

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

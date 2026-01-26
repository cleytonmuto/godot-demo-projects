extends Node

signal mask_changed(new_mask)

enum Mask {
	NEUTRAL,
	GUARD,
	GHOST
}

var current_mask: Mask = Mask.NEUTRAL

func cycle_mask() -> void:
	current_mask = ((current_mask as int) + 1) % Mask.size() as Mask
	mask_changed.emit(current_mask)

func can_enemy_chase() -> bool:
	return current_mask != Mask.GUARD

func can_collide_with_enemy() -> bool:
	return current_mask != Mask.GHOST

func get_mask_color() -> Color:
	match current_mask:
		Mask.NEUTRAL:
			return Color.WHITE
		Mask.GUARD:
			return Color(0.4, 0.6, 1.0)
		Mask.GHOST:
			return Color(0.7, 0.7, 0.7, 0.5)
	return Color.WHITE

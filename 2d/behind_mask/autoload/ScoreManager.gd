extends Node

## Manages scoring system

signal score_changed(new_score: int)
signal combo_changed(new_combo: int)

var score := 0
var combo := 0
var combo_timer := 0.0
var max_combo := 0
const COMBO_TIMEOUT := 2.0

func _ready() -> void:
	add_to_group("score_manager")

func _process(delta: float) -> void:
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			_reset_combo()

func add_kill_score(enemy_type: String = "normal") -> void:
	var base_score := 100
	var score_multiplier := 1.0
	
	match enemy_type:
		"boss":
			base_score = 1000
		"detector", "hunter", "mimic":
			base_score = 200
		"normal":
			base_score = 100
	
	# Combo multiplier
	if combo > 0:
		score_multiplier = 1.0 + (combo * 0.1)
		score_multiplier = min(score_multiplier, 3.0)  # Cap at 3x
	
	var points := int(base_score * score_multiplier)
	score += points
	
	# Increase combo
	combo += 1
	combo_timer = COMBO_TIMEOUT
	max_combo = max(max_combo, combo)
	
	score_changed.emit(score)
	combo_changed.emit(combo)

func _reset_combo() -> void:
	combo = 0
	combo_changed.emit(0)

func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	score_changed.emit(0)
	combo_changed.emit(0)

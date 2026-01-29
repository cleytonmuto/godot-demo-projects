extends Node

## Manages player level, experience, and attribute points (power, health, speed).
## EXP gained per kill = that enemy's max health.

signal exp_changed(current_exp: int, exp_to_next: int, level: int)
signal level_up(new_level: int)
signal stats_changed()

const MAX_LEVEL := 10
const MAX_BONUS_PER_STAT := 10

# Cumulative EXP required to reach level 2, 3, ... 10 (index 0 = level 2, index 8 = level 10) — 5× curve
const EXP_REQUIRED: Array[int] = [400, 1000, 1800, 2800, 4000, 5400, 7000, 8800, 10800]

# Base stats (before bonuses)
const BASE_SWORD_DAMAGE := 10
const BASE_MAX_HEALTH := 50
const BASE_SPEED := 200.0

# Per-point bonuses
const POWER_PER_POINT := 2
const HEALTH_PER_POINT := 5
const SPEED_PER_POINT := 10.0

var level := 1
var exp_total := 0
var unspent_points := 0
var power_bonus := 0
var health_bonus := 0
var speed_bonus := 0


func _ready() -> void:
	add_to_group("experience_manager")


func get_exp_to_next_level() -> int:
	if level >= MAX_LEVEL:
		return 0
	if level == 1:
		return EXP_REQUIRED[0]
	return EXP_REQUIRED[level - 1] - EXP_REQUIRED[level - 2]


func get_exp_in_current_segment() -> int:
	if level >= MAX_LEVEL:
		return get_exp_to_next_level()
	if level == 1:
		return exp_total
	return exp_total - EXP_REQUIRED[level - 2]


func get_exp_progress() -> float:
	var to_next := get_exp_to_next_level()
	if to_next <= 0:
		return 1.0
	var current_segment := get_exp_in_current_segment()
	return clampf(float(current_segment) / float(to_next), 0.0, 1.0)


func add_exp(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		return
	exp_total += amount
	# Check level ups (EXP_REQUIRED[i] = cumulative exp to reach level i+2)
	while level < MAX_LEVEL and exp_total >= EXP_REQUIRED[level - 1]:
		level += 1
		unspent_points += 1
		level_up.emit(level)
	exp_changed.emit(exp_total, get_exp_to_next_level(), level)


func spend_point(stat: StringName) -> bool:
	if unspent_points <= 0:
		return false
	if stat == &"power" and power_bonus < MAX_BONUS_PER_STAT:
		power_bonus += 1
		unspent_points -= 1
		stats_changed.emit()
		return true
	if stat == &"health" and health_bonus < MAX_BONUS_PER_STAT:
		health_bonus += 1
		unspent_points -= 1
		stats_changed.emit()
		return true
	if stat == &"speed" and speed_bonus < MAX_BONUS_PER_STAT:
		speed_bonus += 1
		unspent_points -= 1
		stats_changed.emit()
		return true
	return false


func get_sword_damage() -> int:
	return BASE_SWORD_DAMAGE + power_bonus * POWER_PER_POINT


func get_max_health() -> int:
	return BASE_MAX_HEALTH + health_bonus * HEALTH_PER_POINT


func get_speed() -> float:
	return BASE_SPEED + float(speed_bonus) * SPEED_PER_POINT


func reset() -> void:
	level = 1
	exp_total = 0
	unspent_points = 0
	power_bonus = 0
	health_bonus = 0
	speed_bonus = 0
	exp_changed.emit(exp_total, get_exp_to_next_level(), level)
	stats_changed.emit()

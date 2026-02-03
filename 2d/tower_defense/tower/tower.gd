extends Node2D

## Tower that finds enemies in range and damages them on cooldown.

@export var damage := 15
@export var range_radius := 120.0
@export var fire_interval := 0.8

var _fire_timer := 0.0


func _process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_try_fire()


func _try_fire() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_progress := -1.0
	for node in enemies:
		var enemy := node as Node2D
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist > range_radius:
			continue
		var prog: float = enemy.path_progress if "path_progress" in enemy else 0.0
		if prog > best_progress:
			best_progress = prog
			best = enemy
	if best and best.has_method("take_damage"):
		best.take_damage(damage)

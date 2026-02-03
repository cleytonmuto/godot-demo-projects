extends Node2D

## Enemy that follows a path (world positions). Emits died(gold_reward) and reached_goal().
## path_progress (0..1) is used by towers to target the furthest along.

signal died(reward: int)
signal reached_goal()

@export var max_health := 2
@export var speed := 80.0
@export var gold_reward := 10

var health: int
var path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var path_progress: float = 0.0  # 0..1 for tower targeting


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if path.size() > 0:
		global_position = path[0]


func _process(delta: float) -> void:
	if path_index >= path.size():
		return
	var target := path[path_index]
	var to_target := target - global_position
	var dist := to_target.length()
	if dist < 4.0:
		path_index += 1
		if path_index >= path.size():
			reached_goal.emit()
			queue_free()
			return
		path_progress = float(path_index) / float(path.size())
		return
	global_position += to_target.normalized() * speed * delta
	var total := path.size()
	path_progress = clampf(float(path_index) / max(1, total - 1), 0.0, 1.0) if total > 1 else 0.0


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		died.emit(gold_reward)
		queue_free()

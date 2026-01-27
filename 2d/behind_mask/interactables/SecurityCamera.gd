extends Node2D
class_name SecurityCamera

## Security Camera - Detects player and triggers alarm
## Only Ghost mask avoids detection
## Alarm spawns extra detection for player

@export var detection_angle := 60.0  # Degrees
@export var detection_range := 200.0
@export var rotation_speed := 30.0  # Degrees per second
@export var rotation_range := 90.0  # Total sweep range
@export var stationary := false

@onready var visual := $Visual
@onready var detection_cone := $DetectionCone
@onready var alert_light := $Visual/AlertLight

var base_rotation := 0.0
var sweep_direction := 1
var player: CharacterBody2D
var mask_manager: Node
var is_detecting := false
var alarm_triggered := false

func _ready() -> void:
	base_rotation = rotation_degrees
	_draw_detection_cone()
	alert_light.color = Color.GREEN
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")

func _draw_detection_cone() -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var half_angle := deg_to_rad(detection_angle / 2)
	var segments := 16
	for i in range(segments + 1):
		var angle := -half_angle + (half_angle * 2 * i / segments)
		points.append(Vector2(cos(angle), sin(angle)) * detection_range)
	
	detection_cone.polygon = points
	detection_cone.color = Color(0.2, 0.8, 0.2, 0.15)

func _process(delta: float) -> void:
	if not stationary:
		# Sweep back and forth
		rotation_degrees += rotation_speed * sweep_direction * delta
		if abs(rotation_degrees - base_rotation) > rotation_range / 2:
			sweep_direction *= -1
	
	_check_detection()

func _check_detection() -> void:
	if not is_instance_valid(player) or not mask_manager:
		return
	
	# Ghost mask avoids camera detection
	if mask_manager.current_mask == mask_manager.Mask.GHOST:
		_set_detecting(false)
		return
	
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	
	if distance > detection_range:
		_set_detecting(false)
		return
	
	# Check angle
	var angle_to_player := rad_to_deg(to_player.angle())
	var camera_angle := global_rotation_degrees
	var angle_diff: float = abs(wrapf(angle_to_player - camera_angle, -180, 180))
	
	if angle_diff <= detection_angle / 2:
		_set_detecting(true)
		# Add to player's detection meter
		mask_manager.add_detection(0.02)  # Rapid detection from cameras
	else:
		_set_detecting(false)

func _set_detecting(detecting: bool) -> void:
	if detecting == is_detecting:
		return
	
	is_detecting = detecting
	
	if detecting:
		detection_cone.color = Color(1.0, 0.3, 0.3, 0.25)
		alert_light.color = Color.RED
		if not alarm_triggered:
			_trigger_alarm()
	else:
		detection_cone.color = Color(0.2, 0.8, 0.2, 0.15)
		alert_light.color = Color.GREEN

func _trigger_alarm() -> void:
	alarm_triggered = true
	# Flash the light
	var tween := create_tween().set_loops(3)
	tween.tween_property(alert_light, "color", Color.WHITE, 0.1)
	tween.tween_property(alert_light, "color", Color.RED, 0.1)
	
	# Reset alarm after some time
	await get_tree().create_timer(3.0).timeout
	alarm_triggered = false

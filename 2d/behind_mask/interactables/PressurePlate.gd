extends Area2D
class_name PressurePlate

## Pressure Plate - Triggers connected doors/mechanisms
## Ghost mask is too ethereal to trigger plates!

signal activated
signal deactivated

@export var linked_node_path: NodePath  # Path to door or mechanism to control
@export var stay_activated := false  # If true, stays on after first trigger

@onready var visual := $Visual
@onready var plate := $Visual/Plate

var is_pressed := false
var linked_node: Node

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if linked_node_path:
		linked_node = get_node_or_null(linked_node_path)
	
	_update_visual()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	# Ghost mask can't trigger pressure plates (too light/ethereal)
	if body.has_node("MaskManager"):
		var mask_manager := body.get_node("MaskManager")
		if mask_manager.current_mask == mask_manager.Mask.GHOST:
			return
	
	_activate()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if not stay_activated:
		_deactivate()

func _activate() -> void:
	if is_pressed:
		return
	
	is_pressed = true
	activated.emit()
	_update_visual()
	
	# Notify linked node
	if linked_node and linked_node.has_method("on_plate_activated"):
		linked_node.on_plate_activated()
	
	# Play sound
	AudioManager.play_laser_deactivate()

func _deactivate() -> void:
	if not is_pressed:
		return
	
	is_pressed = false
	deactivated.emit()
	_update_visual()
	
	# Notify linked node
	if linked_node and linked_node.has_method("on_plate_deactivated"):
		linked_node.on_plate_deactivated()
	
	AudioManager.play_laser_activate()

func _update_visual() -> void:
	if is_pressed:
		plate.color = Color(0.2, 0.8, 0.2, 1)
		plate.position.y = 2  # Pressed down
	else:
		plate.color = Color(0.5, 0.5, 0.5, 1)
		plate.position.y = 0

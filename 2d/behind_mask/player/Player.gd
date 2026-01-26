extends CharacterBody2D

@export var speed := 200.0

@onready var mask_manager := $MaskManager
@onready var visual := $Visual
@onready var mask_base := $Visual/MaskBase
@onready var mask_top := $Visual/MaskTop
@onready var mask_chin := $Visual/MaskChin
@onready var brow := $Visual/Brow
@onready var nose_bridge := $Visual/NoseBridge

func _ready() -> void:
	mask_manager.mask_changed.connect(_on_mask_changed)
	_on_mask_changed(mask_manager.current_mask)

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("action"):
		mask_manager.cycle_mask()
	
	if Input.is_action_just_pressed("restart"):
		die()

func _on_mask_changed(_mask: int) -> void:
	var color: Color = mask_manager.get_mask_color()
	# Color all mask parts
	mask_base.color = color
	mask_top.color = color
	mask_chin.color = color
	# Slightly darker shade for details
	var detail_color := color.darkened(0.1)
	brow.color = detail_color
	nose_bridge.color = detail_color
	# Make the visual slightly transparent for ghost mask
	visual.modulate.a = color.a

func die() -> void:
	Game.restart_level()

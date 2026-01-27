extends CharacterBody2D

@export var speed := 200.0

@onready var mask_manager := $MaskManager
@onready var visual := $Visual
@onready var mask_base := $Visual/MaskBase
@onready var mask_top := $Visual/MaskTop
@onready var mask_chin := $Visual/MaskChin
@onready var brow := $Visual/Brow
@onready var nose_bridge := $Visual/NoseBridge
@onready var mask_base_shadow := $Visual/MaskBaseShadow
@onready var mask_top_shadow := $Visual/MaskTopShadow

var is_animating := false

func _ready() -> void:
	mask_manager.mask_changed.connect(_on_mask_changed)
	_apply_mask_color(mask_manager.get_mask_color())

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("restart"):
		die()

func _on_mask_changed(_mask: int) -> void:
	if is_animating:
		return
	is_animating = true
	
	var color: Color = mask_manager.get_mask_color()
	
	# Flash white briefly
	var flash_tween := create_tween()
	flash_tween.tween_property(visual, "modulate", Color(2, 2, 2, 1), 0.05)
	flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	
	# Scale pop effect
	var scale_tween := create_tween()
	scale_tween.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.05)
	scale_tween.tween_property(visual, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Apply colors after brief delay
	await flash_tween.finished
	_apply_mask_color(color)
	is_animating = false

func _apply_mask_color(color: Color) -> void:
	# Color all mask parts
	mask_base.color = color
	mask_top.color = color
	mask_chin.color = color
	# Shadows use darker version
	var shadow_color := color.darkened(0.15)
	if mask_base_shadow:
		mask_base_shadow.color = shadow_color
	if mask_top_shadow:
		mask_top_shadow.color = shadow_color
	# Slightly darker shade for details
	var detail_color := color.darkened(0.1)
	brow.color = detail_color
	nose_bridge.color = detail_color
	# Make the visual slightly transparent for ghost mask
	visual.modulate.a = color.a

func die() -> void:
	Game.restart_level()

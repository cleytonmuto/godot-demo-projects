extends Area2D

## The laser barrier blocks most masks, but Guard mask can pass through.
## Ghost mask cannot pass - the laser detects ethereal forms!

@export var barrier_width := 16.0
@export var barrier_height := 100.0

@onready var visual := $Visual
@onready var collision_shape := $CollisionShape2D

var mask_manager: Node
var is_passable := false

func _ready() -> void:
	# Setup collision shape size
	var shape := RectangleShape2D.new()
	shape.size = Vector2(barrier_width, barrier_height)
	collision_shape.shape = shape
	
	# Setup visual
	visual.size = Vector2(barrier_width, barrier_height)
	visual.position = Vector2(-barrier_width / 2, -barrier_height / 2)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Wait a frame to ensure player is ready
	await get_tree().process_frame
	_connect_to_player()

func _connect_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		_on_mask_changed(mask_manager.current_mask)

func _on_mask_changed(mask: int) -> void:
	# Guard mask (1) can pass through lasers - they recognize the uniform
	var was_passable := is_passable
	is_passable = mask == 1
	
	# Play sound on state change
	if is_passable and not was_passable:
		AudioManager.play_laser_deactivate()
	elif not is_passable and was_passable:
		AudioManager.play_laser_activate()
	
	# Visual feedback
	var tween := create_tween()
	if is_passable:
		tween.tween_property(visual, "modulate", Color(0.3, 1, 0.3, 0.3), 0.2)
		collision_shape.set_deferred("disabled", true)
	else:
		tween.tween_property(visual, "modulate", Color(1, 0.2, 0.2, 0.8), 0.2)
		collision_shape.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_passable:
		if body.has_method("die"):
			body.die()

func _process(_delta: float) -> void:
	# Animate the laser beam
	if not is_passable:
		var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.01)
		visual.modulate.a = pulse

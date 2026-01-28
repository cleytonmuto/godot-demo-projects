extends StaticBody2D
class_name OneWayDoor

## One-Way Door - Can only be passed from one direction
## Forces commitment to a path - no backtracking

@export_enum("Left", "Right", "Up", "Down") var passable_from := 0
@export var door_width := 64.0
@export var door_thickness := 16.0

@onready var visual := $Visual
@onready var collision := $CollisionShape2D
@onready var trigger_area := $TriggerArea

var player_inside := false
var player_entry_side := 0

func _ready() -> void:
	_setup_door()
	trigger_area.body_entered.connect(_on_trigger_entered)
	trigger_area.body_exited.connect(_on_trigger_exited)

func _setup_door() -> void:
	# Setup collision shape
	var shape := RectangleShape2D.new()
	
	# Door orientation based on passable direction
	match passable_from:
		0, 1:  # Left/Right - vertical door
			shape.size = Vector2(door_thickness, door_width)
			visual.size = Vector2(door_thickness, door_width)
			visual.position = Vector2(-door_thickness/2, -door_width/2)
		2, 3:  # Up/Down - horizontal door
			shape.size = Vector2(door_width, door_thickness)
			visual.size = Vector2(door_width, door_thickness)
			visual.position = Vector2(-door_width/2, -door_thickness/2)
	
	collision.shape = shape
	
	# Setup trigger area (slightly larger)
	var trigger_shape := RectangleShape2D.new()
	match passable_from:
		0, 1:
			trigger_shape.size = Vector2(door_thickness + 40, door_width)
		2, 3:
			trigger_shape.size = Vector2(door_width, door_thickness + 40)
	$TriggerArea/CollisionShape2D.shape = trigger_shape
	
	_update_visual()

func _update_visual() -> void:
	# Arrow indicator showing passable direction
	var arrow_color := Color(0.3, 0.8, 0.3, 0.8)
	visual.color = Color(0.4, 0.4, 0.5, 1)
	
	# Add arrow child if not exists
	if not has_node("Arrow"):
		var new_arrow := Label.new()
		new_arrow.name = "Arrow"
		new_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(new_arrow)
	
	var arrow: Label = $Arrow
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", arrow_color)
	
	match passable_from:
		0:  # Left
			arrow.text = "→"
			arrow.position = Vector2(-20, -12)
		1:  # Right
			arrow.text = "←"
			arrow.position = Vector2(-8, -12)
		2:  # Up
			arrow.text = "↓"
			arrow.position = Vector2(-8, -20)
		3:  # Down
			arrow.text = "↑"
			arrow.position = Vector2(-8, -8)

func _on_trigger_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	
	# Determine which side player entered from
	var relative_pos := body.global_position - global_position
	match passable_from:
		0, 1:  # Horizontal check
			player_entry_side = 0 if relative_pos.x < 0 else 1
		2, 3:  # Vertical check
			player_entry_side = 2 if relative_pos.y < 0 else 3
	
	# If entering from passable side, disable collision temporarily
	if player_entry_side == passable_from:
		collision.set_deferred("disabled", true)

func _on_trigger_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	collision.set_deferred("disabled", false)

func _physics_process(_delta: float) -> void:
	if player_inside:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player:
			var relative_pos: Vector2 = player.global_position - global_position
			var _current_side := 0
			match passable_from:
				0, 1:
					_current_side = 0 if relative_pos.x < 0 else 1
				2, 3:
					_current_side = 2 if relative_pos.y < 0 else 3
			
			# Only allow passage if came from correct side
			if player_entry_side == passable_from:
				collision.disabled = true
			else:
				collision.disabled = false

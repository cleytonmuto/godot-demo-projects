extends Camera2D
class_name LevelCamera

## Camera that follows player and scrolls horizontally

@export var follow_speed := 5.0
@export var level_width := 2048.0
@export var level_height := 768.0

var player: CharacterBody2D
var target_x := 0.0

func _ready() -> void:
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Set camera limits
	limit_left = 0
	limit_right = int(level_width)
	limit_top = 0
	limit_bottom = int(level_height)
	
	# Set initial position
	if player:
		global_position.x = player.global_position.x
		global_position.y = level_height / 2.0

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Follow player horizontally, keep vertical centered
	target_x = player.global_position.x
	global_position.x = lerp(global_position.x, target_x, follow_speed * get_process_delta_time())
	global_position.y = level_height / 2.0

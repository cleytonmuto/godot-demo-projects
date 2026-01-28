extends Camera2D
class_name LevelCamera

## Camera that follows player and scrolls horizontally

# follow_speed removed - camera now follows player instantly to keep them centered
@export var level_width := 2048.0
@export var level_height := 768.0

var player: CharacterBody2D
var target_x := 0.0
var half_viewport_width := 512.0
var initialized := false

func _ready() -> void:
	# Ensure camera is enabled
	enabled = true
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Cache half viewport width from current viewport
	var viewport_size := get_viewport_rect().size
	half_viewport_width = viewport_size.x / 2.0
	
	# Set camera limits to level bounds (we'll handle clamping manually)
	limit_left = 0
	limit_right = int(level_width)
	limit_top = 0
	limit_bottom = int(level_height)
	
	# Wait for player to be positioned, then set camera to start at player's position
	await get_tree().process_frame
	_initialize_camera_position()

func _physics_process(_delta: float) -> void:
	if not initialized:
		return  # Skip processing until camera is initialized
	
	if not player or not is_instance_valid(player):
		return
	
	# Always center the player on screen - camera position = player position
	# But clamp to prevent showing outside level bounds
	# Left edge: camera must be at least half_viewport_width so left edge of screen (camera.x - half_viewport_width) >= 0
	# Right edge: camera must be at most (level_width - half_viewport_width) so right edge (camera.x + half_viewport_width) <= level_width
	var desired_x: float = player.global_position.x
	var clamped_x: float = clamp(
		desired_x,
		half_viewport_width,
		level_width - half_viewport_width
	)
	
	# Set camera position directly to keep player centered (or clamped if at edges)
	global_position.x = clamped_x
	global_position.y = player.global_position.y

func _initialize_camera_position() -> void:
	# Start camera at the player's position so the player is centered
	if player and is_instance_valid(player):
		# Clamp to level bounds
		var player_x: float = player.global_position.x
		var clamped_x: float = clamp(
			player_x,
			half_viewport_width,
			level_width - half_viewport_width
		)
		global_position.x = clamped_x
		global_position.y = player.global_position.y
	else:
		# Fallback: start at leftmost position
		global_position.x = half_viewport_width
		global_position.y = level_height / 2.0
	
	# Mark as initialized so _process can start working
	initialized = true

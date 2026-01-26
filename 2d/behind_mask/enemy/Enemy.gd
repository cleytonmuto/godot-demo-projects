extends CharacterBody2D

@export var speed := 100.0
@export var chase_speed := 140.0
@export var patrol_distance := 64.0

var start_position: Vector2
var direction := 1
var chasing := false
var player: CharacterBody2D
var mask_manager: Node

func _ready() -> void:
	start_position = global_position
	# Wait a frame to ensure player is ready
	await get_tree().process_frame
	_connect_to_player()

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		_on_mask_changed(mask_manager.current_mask)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	if chasing:
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * chase_speed
	else:
		# Patrol left and right
		velocity.x = direction * speed
		velocity.y = 0
		if abs(global_position.x - start_position.x) > patrol_distance:
			direction *= -1
	
	move_and_slide()
	
	# Check collision with player
	var distance := global_position.distance_to(player.global_position)
	if distance < 24.0:
		if mask_manager and mask_manager.can_collide_with_enemy():
			player.die()

func _on_mask_changed(_mask: int) -> void:
	if mask_manager:
		chasing = mask_manager.can_enemy_chase()

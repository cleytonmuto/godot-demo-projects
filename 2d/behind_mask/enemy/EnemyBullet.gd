extends Area2D
class_name EnemyBullet

## Bullet fired by enemies

@export var speed := 300.0
@export var damage := 1
@export var lifetime := 3.0

var direction := Vector2.ZERO
var lifetime_timer := 0.0

@onready var visual := $Visual
@onready var collision_shape := $CollisionShape2D

func _ready() -> void:
	# Create bullet visual
	_create_visual()
	# Connect collision
	body_entered.connect(_on_body_entered)
	# Add to bullets group
	add_to_group("enemy_bullets")

func _create_visual() -> void:
	# Create a bright red bullet
	var bullet := ColorRect.new()
	bullet.name = "Bullet"
	bullet.offset_left = -4.0
	bullet.offset_top = -4.0
	bullet.offset_right = 4.0
	bullet.offset_bottom = 4.0
	bullet.color = Color(1.0, 0.2, 0.2, 1.0)
	visual.add_child(bullet)
	
	# Add glow
	var glow := ColorRect.new()
	glow.name = "Glow"
	glow.offset_left = -6.0
	glow.offset_top = -6.0
	glow.offset_right = 6.0
	glow.offset_bottom = 6.0
	glow.color = Color(1.0, 0.4, 0.4, 0.5)
	visual.add_child(glow)
	
	# Make glow behind bullet
	glow.z_index = -1

func _physics_process(delta: float) -> void:
	# Move bullet
	global_position += direction * speed * delta
	
	# Update lifetime
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		queue_free()
	
	# Rotate for visual effect
	visual.rotation += delta * 10.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()

func setup(start_pos: Vector2, target_pos: Vector2) -> void:
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	visual.rotation = direction.angle()

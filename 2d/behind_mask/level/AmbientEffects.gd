extends Node2D
class_name AmbientEffects

## Creates ambient effects like dust particles and floating debris

@export var dust_density := 0.5
@export var debris_count := 15

var dust_particles: Array[CPUParticles2D] = []
# Use a generic array because debris are ColorRect (Controls), not Node2D
var debris_nodes: Array = []

func _ready() -> void:
	_create_dust_effects()
	_create_floating_debris()

func _create_dust_effects() -> void:
	# Create multiple dust particle systems
	var count := int(dust_density * 5)
	for i in range(count):
		var dust := CPUParticles2D.new()
		dust.position = Vector2(randf_range(0, 2048), randf_range(0, 768))
		dust.emitting = true
		dust.amount = 20
		dust.lifetime = 3.0
		dust.emission_shape = 1  # EMISSION_SHAPE_CIRCLE
		dust.emission_sphere_radius = 100.0
		dust.direction = Vector2(0, -1)
		dust.initial_velocity_min = 10.0
		dust.initial_velocity_max = 30.0
		dust.gravity = Vector2(0, 20)
		dust.color = Color(0.7, 0.6, 0.5, 0.3)
		dust.scale_amount_min = 0.3
		dust.scale_amount_max = 0.8
		
		add_child(dust)
		dust_particles.append(dust)

func _create_floating_debris() -> void:
	# Create floating debris pieces
	for i in range(debris_count):
		var debris := ColorRect.new()
		debris.size = Vector2(randf_range(4, 12), randf_range(4, 12))
		debris.position = Vector2(randf_range(0, 2048), randf_range(0, 768))
		debris.color = Color(randf_range(0.3, 0.6), randf_range(0.3, 0.6), randf_range(0.3, 0.6), 0.5)
		
		# Add floating animation
		var tween := create_tween()
		tween.set_loops()
		var start_y := debris.position.y
		tween.tween_property(debris, "position:y", start_y - randf_range(20, 50), randf_range(2, 4))
		tween.tween_property(debris, "position:y", start_y, randf_range(2, 4))
		
		# Slow horizontal drift
		var drift_tween := create_tween()
		drift_tween.set_loops()
		var start_x := debris.position.x
		drift_tween.tween_property(debris, "position:x", start_x + randf_range(-30, 30), randf_range(3, 6))
		drift_tween.tween_property(debris, "position:x", start_x, randf_range(3, 6))
		
		add_child(debris)
		debris_nodes.append(debris)

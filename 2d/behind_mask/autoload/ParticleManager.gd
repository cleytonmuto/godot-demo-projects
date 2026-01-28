extends Node

## Manages particle effects for hits, explosions, etc.

static var instance: Node

func _ready() -> void:
	instance = self
	add_to_group("particle_manager")

static func create_hit_sparks(position: Vector2, color: Color = Color(1, 1, 0.8)) -> void:
	if not instance:
		return
	
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.3
	particles.emission_shape = 1  # EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 5.0
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 200)
	particles.color = color
	
	# Add to scene
	var scene: Node = Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(particles)
		particles.finished.connect(func(): particles.queue_free())

static func create_explosion(position: Vector2, scale: float = 1.0, color: Color = Color(1, 0.5, 0.1)) -> void:
	if not instance:
		return
	
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = int(30 * scale)
	particles.lifetime = 0.5 * scale
	particles.emission_shape = 1  # EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 10.0 * scale
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 100.0 * scale
	particles.initial_velocity_max = 300.0 * scale
	particles.gravity = Vector2(0, 100)
	particles.color = color
	particles.scale_amount_min = 1.0 * scale
	particles.scale_amount_max = 2.0 * scale
	
	var scene: Node = Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(particles)
		particles.finished.connect(func(): particles.queue_free())

static func create_dust(position: Vector2, direction: Vector2 = Vector2.ZERO) -> void:
	if not instance:
		return
	
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 8
	particles.lifetime = 1.0
	particles.emission_shape = 1  # EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 3.0
	particles.direction = direction if direction != Vector2.ZERO else Vector2(0, -1)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2(0, 50)
	particles.color = Color(0.6, 0.5, 0.4, 0.6)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	
	var scene: Node = Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(particles)
		particles.finished.connect(func(): particles.queue_free())

extends Node

## Manages particle effects for hits, explosions, etc.
## Uses GPU particle scenes (from 2d/particles demo style) when available; falls back to CPUParticles2D.

static var instance: Node

var _hit_sparks_scene: PackedScene
var _explosion_scene: PackedScene
var _dust_scene: PackedScene

func _ready() -> void:
	instance = self
	add_to_group("particle_manager")
	_hit_sparks_scene = load("res://art/particles/HitSparksParticles.tscn") as PackedScene
	_explosion_scene = load("res://art/particles/ExplosionParticles.tscn") as PackedScene
	_dust_scene = load("res://art/particles/DustParticles.tscn") as PackedScene

static func create_hit_sparks(position: Vector2, color: Color = Color(1, 1, 0.8)) -> void:
	if not instance:
		return
	
	var scene: Node = Engine.get_main_loop().current_scene
	if not scene:
		return
	
	# Prefer GPU particle scene (textured, additive blend)
	var packed: PackedScene = instance._hit_sparks_scene
	var particles: Node2D = (packed.instantiate() as Node2D) if packed else null
	if particles:
		particles.position = position
		particles.emitting = true
		scene.add_child(particles)
		particles.finished.connect(func(): particles.queue_free())
		return
	
	# Fallback: CPU particles
	var cpu := CPUParticles2D.new()
	cpu.position = position
	cpu.emitting = true
	cpu.amount = 15
	cpu.lifetime = 0.3
	cpu.emission_shape = 1
	cpu.emission_sphere_radius = 5.0
	cpu.direction = Vector2(0, -1)
	cpu.initial_velocity_min = 50.0
	cpu.initial_velocity_max = 150.0
	cpu.gravity = Vector2(0, 200)
	cpu.color = color
	scene.add_child(cpu)
	cpu.finished.connect(func(): cpu.queue_free())

static func create_explosion(position: Vector2, scale: float = 1.0, color: Color = Color(1, 0.5, 0.1)) -> void:
	if not instance:
		return
	
	var scene: Node = Engine.get_main_loop().current_scene
	if not scene:
		return
	
	var packed: PackedScene = instance._explosion_scene
	var particles: Node2D = (packed.instantiate() as Node2D) if packed else null
	if particles:
		particles.position = position
		particles.scale = Vector2(scale, scale)
		particles.emitting = true
		scene.add_child(particles)
		particles.finished.connect(func(): particles.queue_free())
		return
	
	var cpu := CPUParticles2D.new()
	cpu.position = position
	cpu.emitting = true
	cpu.amount = int(30 * scale)
	cpu.lifetime = 0.5 * scale
	cpu.emission_shape = 1
	cpu.emission_sphere_radius = 10.0 * scale
	cpu.direction = Vector2(0, -1)
	cpu.initial_velocity_min = 100.0 * scale
	cpu.initial_velocity_max = 300.0 * scale
	cpu.gravity = Vector2(0, 100)
	cpu.color = color
	cpu.scale_amount_min = 1.0 * scale
	cpu.scale_amount_max = 2.0 * scale
	scene.add_child(cpu)
	cpu.finished.connect(func(): cpu.queue_free())

static func create_dust(position: Vector2, direction: Vector2 = Vector2.ZERO) -> void:
	if not instance:
		return
	
	var scene: Node = Engine.get_main_loop().current_scene
	if not scene:
		return
	
	var packed: PackedScene = instance._dust_scene
	var particles: Node2D = (packed.instantiate() as Node2D) if packed else null
	if particles:
		particles.position = position
		particles.emitting = true
		scene.add_child(particles)
		particles.finished.connect(func(): particles.queue_free())
		return
	
	var cpu := CPUParticles2D.new()
	cpu.position = position
	cpu.emitting = true
	cpu.amount = 8
	cpu.lifetime = 1.0
	cpu.emission_shape = 1
	cpu.emission_sphere_radius = 3.0
	cpu.direction = direction if direction != Vector2.ZERO else Vector2(0, -1)
	cpu.initial_velocity_min = 20.0
	cpu.initial_velocity_max = 60.0
	cpu.gravity = Vector2(0, 50)
	cpu.color = Color(0.6, 0.5, 0.4, 0.6)
	cpu.scale_amount_min = 0.5
	cpu.scale_amount_max = 1.5
	scene.add_child(cpu)
	cpu.finished.connect(func(): cpu.queue_free())

static func create_heal_burst(position: Vector2) -> void:
	## Green upward burst when player picks up a life potion.
	if not instance:
		return
	var scene: Node = Engine.get_main_loop().current_scene
	if not scene:
		return
	var cpu := CPUParticles2D.new()
	cpu.position = position
	cpu.emitting = true
	cpu.one_shot = true
	cpu.amount = 24
	cpu.lifetime = 0.5
	cpu.emission_shape = 1
	cpu.emission_sphere_radius = 8.0
	cpu.direction = Vector2(0, -1)
	cpu.spread = 90.0
	cpu.initial_velocity_min = 80.0
	cpu.initial_velocity_max = 180.0
	cpu.gravity = Vector2(0, -60)
	cpu.color = Color(0.3, 1.0, 0.5, 0.9)
	cpu.scale_amount_min = 1.2
	cpu.scale_amount_max = 2.0
	scene.add_child(cpu)
	cpu.finished.connect(func(): cpu.queue_free())

static func create_heal_drop(position: Vector2) -> void:
	## Small green sparkles when a life potion drops from an enemy.
	if not instance:
		return
	var scene: Node = Engine.get_main_loop().current_scene
	if not scene:
		return
	var cpu := CPUParticles2D.new()
	cpu.position = position
	cpu.emitting = true
	cpu.one_shot = true
	cpu.amount = 12
	cpu.lifetime = 0.4
	cpu.emission_shape = 1
	cpu.emission_sphere_radius = 6.0
	cpu.direction = Vector2(0, -1)
	cpu.spread = 180.0
	cpu.initial_velocity_min = 20.0
	cpu.initial_velocity_max = 60.0
	cpu.gravity = Vector2(0, 40)
	cpu.color = Color(0.4, 1.0, 0.6, 0.8)
	cpu.scale_amount_min = 0.6
	cpu.scale_amount_max = 1.2
	scene.add_child(cpu)
	cpu.finished.connect(func(): cpu.queue_free())

extends Area2D
class_name LifePotion

## Life potion pickup. Heals 20% of player's max health when collected.
## Spawned by enemies on death (10% drop chance).

const HEAL_PERCENT := 0.20  # 20% of max health

@onready var visual: Node2D = $Visual
@onready var idle_particles: CPUParticles2D = get_node_or_null("IdleParticles")

var _bob_offset := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # player
	_apply_rounded_corners(visual)
	if idle_particles:
		idle_particles.emitting = true

func _apply_rounded_corners(node: Node) -> void:
	var shader := load("res://art/rounded_corners.gdshader") as Shader
	for child in node.get_children():
		if child is ColorRect:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			child.material = mat
		else:
			_apply_rounded_corners(child)

func _process(delta: float) -> void:
	# Gentle float/bob
	_bob_offset += delta * 2.5
	if visual:
		visual.position.y = sin(_bob_offset) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.has_method("heal"):
		return
	# Heal 20% of player's max health
	var max_hp: int = body.max_health if "max_health" in body else 50
	var heal_amount: int = maxi(1, int(max_hp * HEAL_PERCENT))
	body.heal(heal_amount)
	# Pickup particles (heal burst)
	ParticleManager.create_heal_burst(global_position)
	AudioManager.play_potion_pickup()
	queue_free()

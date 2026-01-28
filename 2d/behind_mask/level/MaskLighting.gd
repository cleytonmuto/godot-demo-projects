extends Node2D
class_name MaskLighting

## Dynamic lighting that changes based on current mask

@export var light_intensity := 1.0
@export var light_radius := 300.0

var light: PointLight2D
var player: CharacterBody2D
var mask_manager: Node

func _ready() -> void:
	# Create light
	light = PointLight2D.new()
	light.texture_scale = light_radius
	light.energy = light_intensity
	light.shadow_enabled = true
	add_child(light)
	
	# Find player and mask manager
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		_on_mask_changed(mask_manager.current_mask)

func _process(_delta: float) -> void:
	if player and is_instance_valid(player):
		light.global_position = player.global_position

func _on_mask_changed(mask: int) -> void:
	if not mask_manager:
		return
	
	var mask_color: Color = mask_manager.get_mask_color()
	
	# Adjust light color and intensity based on mask
	match mask:
		mask_manager.Mask.NEUTRAL:
			light.color = Color.WHITE
			light.energy = 0.8
		mask_manager.Mask.GUARD:
			light.color = Color(0.4, 0.6, 1.0)
			light.energy = 1.2
		mask_manager.Mask.GHOST:
			light.color = Color(0.7, 0.7, 0.7)
			light.energy = 0.5
		mask_manager.Mask.PREDATOR:
			light.color = Color(1.0, 0.3, 0.3)
			light.energy = 1.5
		mask_manager.Mask.DECOY:
			light.color = Color(1.0, 0.9, 0.3)
			light.energy = 1.0
	
	# Smooth transition
	var tween := create_tween()
	tween.tween_property(light, "color", light.color, 0.3)
	tween.parallel().tween_property(light, "energy", light.energy, 0.3)

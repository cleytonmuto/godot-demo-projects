extends Node2D
class_name DamageNumber

## Floating damage number

@export var lifetime := 1.0
@export var float_speed := 50.0

var value: int
var label: Label

func _ready() -> void:
	label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	
	# Animate
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_speed, lifetime)
	tween.tween_property(label, "modulate:a", 0.0, lifetime)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), lifetime * 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), lifetime * 0.7).set_delay(lifetime * 0.3)
	
	await tween.finished
	queue_free()

static func create(position: Vector2, damage: int) -> void:
	var damage_num := DamageNumber.new()
	damage_num.value = damage
	damage_num.position = position
	
	var scene: Node = Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(damage_num)

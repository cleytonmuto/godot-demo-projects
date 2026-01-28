extends Node

## Manages screen effects like slow-mo, flashes, etc.

static var instance: Node
var slow_mo_active := false

func _ready() -> void:
	instance = self
	add_to_group("effect_manager")

static func slow_mo(duration: float = 0.2, scale: float = 0.3) -> void:
	if not instance:
		return
	
	if instance.slow_mo_active:
		return
	
	instance.slow_mo_active = true
	Engine.time_scale = scale
	
	await Engine.get_main_loop().create_timer(duration).timeout
	
	Engine.time_scale = 1.0
	instance.slow_mo_active = false

static func flash_screen(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	if not instance:
		return
	
	var flash := ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 1000
	
	var scene: Node = Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(flash)
		
		var tween := flash.create_tween()
		tween.tween_property(flash, "color:a", 0.0, duration)
		tween.tween_callback(func(): flash.queue_free())

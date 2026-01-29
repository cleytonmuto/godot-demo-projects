extends Node

var current_level_path: String = ""
var is_restarting := false

func _ready() -> void:
	# The main scene is loaded automatically, so we track it
	pass

func load_level(path: String) -> void:
	current_level_path = path
	get_tree().change_scene_to_file(path)
	# Start BGM if loading a gameplay level
	if "level" in path:
		AudioManager.play_bgm()
		# Reset score and EXP when starting from level 1 (new run)
		if "level_01" in path:
			var exp_mgr := get_node_or_null("/root/ExperienceManager")
			if exp_mgr and exp_mgr.has_method("reset"):
				exp_mgr.reset()
		await get_tree().process_frame
		var score_mgr := get_node("/root/ScoreManager")
		if score_mgr and score_mgr.has_method("reset"):
			score_mgr.reset()

func restart_level() -> void:
	if is_restarting:
		return
	is_restarting = true
	
	# Play death sound
	AudioManager.play_death()
	
	# Screen shake before restart
	await _do_screen_shake()
	
	# Get the current scene path if not set
	var level_path: String = current_level_path
	if level_path == "":
		var current_scene := get_tree().current_scene
		if current_scene:
			level_path = current_scene.scene_file_path
			if level_path != "":
				current_level_path = level_path
	
	if level_path != "":
		get_tree().change_scene_to_file(level_path)
	else:
		# Fallback: reload the current scene
		get_tree().reload_current_scene()
	
	is_restarting = false

func _do_screen_shake() -> void:
	var canvas := get_tree().root
	var original_offset := Vector2.ZERO
	
	# Create shake effect using CanvasLayer offset
	var shake_layer := CanvasLayer.new()
	shake_layer.name = "ShakeEffect"
	get_tree().current_scene.add_child(shake_layer)
	
	# Flash red briefly
	var flash := ColorRect.new()
	flash.color = Color(1, 0, 0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_layer.add_child(flash)
	
	# Animate flash out
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3)
	
	# Do shake by moving the current scene
	var scene := get_tree().current_scene
	var original_pos: Vector2 = scene.position if scene is Node2D else Vector2.ZERO
	
	if scene is Node2D:
		var tween := create_tween()
		for i in range(6):
			var offset := Vector2(randf_range(-10, 10), randf_range(-10, 10))
			tween.tween_property(scene, "position", original_pos + offset, 0.04)
		tween.tween_property(scene, "position", original_pos, 0.04)
		await tween.finished
	else:
		await get_tree().create_timer(0.25).timeout
	
	shake_layer.queue_free()

func shake_camera(intensity: float = 0.1, duration: float = 0.2) -> void:
	# Try to find camera
	var scene := get_tree().current_scene
	if not scene:
		return
	
	var cam := scene.get_node_or_null("Camera2D")
	if not cam:
		return
	
	var original_offset: Vector2 = cam.offset
	var tween := create_tween()
	
	for i in range(int(duration * 25)):
		var offset: Vector2 = Vector2(
			randf_range(-intensity * 10, intensity * 10),
			randf_range(-intensity * 10, intensity * 10)
		)
		tween.tween_property(cam, "offset", original_offset + offset, 0.04)
	
	tween.tween_property(cam, "offset", original_offset, 0.1)

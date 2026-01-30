extends Control

func _ready() -> void:
	AudioManager.stop_bgm()

func _input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if event.is_action_pressed("action"):
		# Restart from stage 1 with full health, same experience/level/attributes
		Game.load_level("res://level/level_01.tscn", true)
		if viewport:
			viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://main.tscn")
		if viewport:
			viewport.set_input_as_handled()

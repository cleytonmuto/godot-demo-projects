extends Control

func _ready() -> void:
	# Stop BGM when showing win screen
	AudioManager.stop_bgm()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		# Return to title screen
		get_tree().change_scene_to_file("res://main.tscn")

extends Node

var current_level_path: String = ""

func _ready() -> void:
	# The main scene is loaded automatically, so we track it
	pass

func load_level(path: String) -> void:
	current_level_path = path
	get_tree().change_scene_to_file(path)

func restart_level() -> void:
	if current_level_path != "":
		get_tree().change_scene_to_file(current_level_path)
	else:
		# If no level is set, reload the current scene
		get_tree().reload_current_scene()

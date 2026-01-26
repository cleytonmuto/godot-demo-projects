extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		Game.load_level("res://level/level_01.tscn")

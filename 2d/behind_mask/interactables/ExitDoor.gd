extends Area2D

@export var next_level_path: String

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		AudioManager.play_level_complete()
		Game.load_level(next_level_path)

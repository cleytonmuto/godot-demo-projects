extends Area2D

@export var next_level_path: String

func _on_body_entered(body):
    if body.is_in_group("player"):
        Game.load_level(next_level_path)

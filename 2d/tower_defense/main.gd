extends Control

## Main menu: Map Editor or Play (game uses saved map).

func _ready() -> void:
	var editor_btn := $MarginContainer/VBox/MapEditorBtn as Button
	var play_btn := $MarginContainer/VBox/PlayBtn as Button
	editor_btn.pressed.connect(_on_map_editor)
	play_btn.pressed.connect(_on_play)


func _on_map_editor() -> void:
	get_tree().change_scene_to_file("res://map_editor.tscn")


func _on_play() -> void:
	get_tree().change_scene_to_file("res://game.tscn")

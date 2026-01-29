extends Control

## Handles Escape: close command panel if open, else unpause.
## process_mode is set to ALWAYS so this runs while the tree is paused.

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		var hud: Node = get_parent()
		if hud.has_method("close_command_panel_if_visible") and hud.close_command_panel_if_visible():
			get_viewport().set_input_as_handled()
			return
		get_tree().paused = false
		visible = false
		get_viewport().set_input_as_handled()

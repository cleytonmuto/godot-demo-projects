extends CanvasLayer

@onready var mask_label: Label = %MaskLabel
@onready var hint_label: Label = %HintLabel

var player: Node

func _ready() -> void:
	# Wait a frame for player to be ready
	await get_tree().process_frame
	_connect_to_player()

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		var mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		_on_mask_changed(mask_manager.current_mask)

func _on_mask_changed(mask: int) -> void:
	var mask_manager = player.get_node("MaskManager")
	var mask_names := ["NEUTRAL", "GUARD", "GHOST"]
	var mask_hints := [
		"Enemies will chase you!",
		"Enemies ignore you",
		"Pass through enemies"
	]
	
	mask_label.text = "Mask: " + mask_names[mask]
	mask_label.modulate = mask_manager.get_mask_color()
	hint_label.text = mask_hints[mask]

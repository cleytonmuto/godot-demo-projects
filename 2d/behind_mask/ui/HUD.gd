extends CanvasLayer

@onready var mask_icons: HBoxContainer = %MaskIcons
@onready var hint_label: Label = %HintLabel
@onready var cooldown_bar: ProgressBar = %CooldownBar

var player: Node
var mask_manager: Node
var mask_icon_nodes: Array[ColorRect] = []

func _ready() -> void:
	# Wait a frame for player to be ready
	await get_tree().process_frame
	_connect_to_player()
	_setup_mask_icons()

func _setup_mask_icons() -> void:
	# Collect mask icon nodes (Mask0, Mask1, etc.)
	for i in range(5):
		var icon := mask_icons.get_node("Mask" + str(i)) as ColorRect
		if icon:
			mask_icon_nodes.append(icon)

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		mask_manager.cooldown_changed.connect(_on_cooldown_changed)
		_on_mask_changed(mask_manager.current_mask)
		cooldown_bar.max_value = mask_manager.cooldown_time

func _on_mask_changed(mask: int) -> void:
	if not mask_manager:
		return
	
	hint_label.text = mask_manager.get_mask_hint()
	
	# Highlight current mask, dim others
	for i in range(mask_icon_nodes.size()):
		var icon := mask_icon_nodes[i]
		if i == mask:
			# Current mask - larger and fully visible
			_animate_icon_select(icon, true)
		else:
			# Other masks - smaller and dimmed
			_animate_icon_select(icon, false)

func _animate_icon_select(icon: ColorRect, selected: bool) -> void:
	var tween := create_tween()
	if selected:
		tween.tween_property(icon, "custom_minimum_size", Vector2(44, 44), 0.1)
		tween.parallel().tween_property(icon, "modulate", Color.WHITE, 0.1)
		# Add a border effect by scaling
		icon.pivot_offset = icon.size / 2
	else:
		tween.tween_property(icon, "custom_minimum_size", Vector2(28, 28), 0.1)
		tween.parallel().tween_property(icon, "modulate", Color(0.6, 0.6, 0.6, 0.7), 0.1)

func _on_cooldown_changed(remaining: float) -> void:
	cooldown_bar.value = remaining
	
	# Visual feedback when cooldown is active
	if remaining > 0:
		cooldown_bar.modulate = Color(1, 0.5, 0.5)
	else:
		cooldown_bar.modulate = Color(0.5, 1, 0.5)

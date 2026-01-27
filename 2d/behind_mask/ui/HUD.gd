extends CanvasLayer

@onready var mask_icons: HBoxContainer = %MaskIcons
@onready var hint_label: Label = %HintLabel
@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var detection_bar: ProgressBar = %DetectionBar
@onready var stats_label: Label = %StatsLabel
@onready var charges_container: HBoxContainer = %ChargesContainer

var player: Node
var mask_manager: Node
var mask_icon_nodes: Array[ColorRect] = []
var charge_labels: Array[Label] = []

func _ready() -> void:
	# Wait a frame for player to be ready
	await get_tree().process_frame
	_connect_to_player()
	_setup_mask_icons()
	_setup_charge_labels()

func _setup_mask_icons() -> void:
	# Collect mask icon nodes (Mask0, Mask1, etc.)
	for i in range(5):
		var icon := mask_icons.get_node("Mask" + str(i)) as ColorRect
		if icon:
			mask_icon_nodes.append(icon)

func _setup_charge_labels() -> void:
	# Create charge count labels for each mask
	for child in charges_container.get_children():
		if child is Label:
			charge_labels.append(child as Label)

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("MaskManager"):
		mask_manager = player.get_node("MaskManager")
		mask_manager.mask_changed.connect(_on_mask_changed)
		mask_manager.cooldown_changed.connect(_on_cooldown_changed)
		mask_manager.detection_changed.connect(_on_detection_changed)
		mask_manager.charges_changed.connect(_on_charges_changed)
		_on_mask_changed(mask_manager.current_mask)
		_update_all_charges()
		cooldown_bar.max_value = mask_manager.get_cooldown_time()

func _on_mask_changed(mask: int) -> void:
	if not mask_manager:
		return
	
	hint_label.text = mask_manager.get_mask_hint()
	cooldown_bar.max_value = mask_manager.get_cooldown_time()
	
	# Update stats
	stats_label.text = "Switches: %d" % mask_manager.total_mask_switches
	
	# Highlight current mask, dim others
	for i in range(mask_icon_nodes.size()):
		var icon := mask_icon_nodes[i]
		if i == mask:
			_animate_icon_select(icon, true)
		else:
			_animate_icon_select(icon, false)
	
	_update_all_charges()

func _animate_icon_select(icon: ColorRect, selected: bool) -> void:
	var tween := create_tween()
	if selected:
		tween.tween_property(icon, "custom_minimum_size", Vector2(32, 32), 0.1)
		tween.parallel().tween_property(icon, "modulate", Color.WHITE, 0.1)
		icon.pivot_offset = icon.size / 2
	else:
		tween.tween_property(icon, "custom_minimum_size", Vector2(20, 20), 0.1)
		tween.parallel().tween_property(icon, "modulate", Color(0.6, 0.6, 0.6, 0.7), 0.1)

func _on_cooldown_changed(remaining: float) -> void:
	cooldown_bar.value = remaining
	
	if remaining > 0:
		cooldown_bar.modulate = Color(1, 0.5, 0.5)
	else:
		cooldown_bar.modulate = Color(0.5, 1, 0.5)

func _on_detection_changed(level: float) -> void:
	detection_bar.value = level
	
	# Color based on danger level
	if level > 0.7:
		detection_bar.modulate = Color(1, 0.2, 0.2)
	elif level > 0.4:
		detection_bar.modulate = Color(1, 0.6, 0.2)
	else:
		detection_bar.modulate = Color(0.2, 0.8, 0.2)

func _on_charges_changed(mask: int, remaining: int) -> void:
	_update_charge_label(mask, remaining)

func _update_all_charges() -> void:
	if not mask_manager:
		return
	for i in range(charge_labels.size()):
		var charges: int = mask_manager.get_charges(i)
		_update_charge_label(i, charges)

func _update_charge_label(mask: int, charges: int) -> void:
	if mask >= charge_labels.size():
		return
	var label := charge_labels[mask]
	if charges == -1:
		label.text = "∞"
		label.modulate = Color.WHITE
	elif charges == 0:
		label.text = "0"
		label.modulate = Color(0.5, 0.5, 0.5)
	else:
		label.text = str(charges)
		label.modulate = Color.WHITE

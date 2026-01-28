extends CanvasLayer

@onready var mask_icons: HBoxContainer = %MaskIcons
@onready var hint_label: Label = %HintLabel
@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var detection_bar: ProgressBar = %DetectionBar
@onready var stats_label: Label = %StatsLabel
@onready var charges_container: HBoxContainer = %ChargesContainer
@onready var health_bar: ProgressBar = %HealthBar
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var boss_health_bar: ProgressBar = %BossHealthBar
@onready var boss_health_label: Label = %BossHealthLabel

var player: Node
var mask_manager: Node
var mask_icon_nodes: Array[ColorRect] = []
var charge_labels: Array[Label] = []
var boss: Node = null

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
		cooldown_bar.max_value = 3.0  # 3 seconds per mask
		
		# Connect health signal
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
			# Initialize health bar
			health_bar.max_value = player.max_health
			health_bar.value = player.health
		
		# Connect score signals
		ScoreManager.score_changed.connect(_on_score_changed)
		ScoreManager.combo_changed.connect(_on_combo_changed)
		_on_score_changed(ScoreManager.score)
		_on_combo_changed(ScoreManager.combo)
	
	# Connect to boss if present (e.g. Level 4)
	var boss_node := get_tree().get_first_node_in_group("bosses")
	if boss_node:
		boss = boss_node
		if boss.has_signal("boss_health_changed"):
			boss.boss_health_changed.connect(_on_boss_health_changed)
			# Initialize boss health bar using exported boss_health
			if boss_health_bar:
				boss_health_bar.visible = true
				boss_health_bar.max_value = boss.boss_health
				boss_health_bar.value = boss.boss_health
				boss_health_label.visible = true

func _on_mask_changed(mask: int) -> void:
	if not mask_manager:
		return
	
	hint_label.text = mask_manager.get_mask_hint()
	cooldown_bar.max_value = 3.0  # 3 seconds per mask
	cooldown_bar.value = 3.0  # Reset to full when mask changes
	
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
	
	# Color based on time remaining (more urgent as time runs out)
	if remaining < 0.5:
		cooldown_bar.modulate = Color(1, 0.3, 0.3)  # Red - about to change
	elif remaining < 1.0:
		cooldown_bar.modulate = Color(1, 0.7, 0.3)  # Orange
	else:
		cooldown_bar.modulate = Color(0.3, 0.7, 1)  # Blue - plenty of time

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

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	
	# Color based on health level
	if current <= max_health * 0.3:
		health_bar.modulate = Color(1, 0.2, 0.2)  # Red - critical
	elif current <= max_health * 0.6:
		health_bar.modulate = Color(1, 0.7, 0.2)  # Orange
	else:
		health_bar.modulate = Color(0.2, 0.8, 0.2)  # Green

func _on_boss_health_changed(current: int, max_health: int) -> void:
	if not boss_health_bar:
		return
	
	boss_health_bar.visible = true
	boss_health_bar.max_value = max_health
	boss_health_bar.value = current
	
	# Color based on boss health level
	if current <= max_health * 0.3:
		boss_health_bar.modulate = Color(1, 0.2, 0.2)  # Red - near death
	elif current <= max_health * 0.6:
		boss_health_bar.modulate = Color(1, 0.7, 0.2)  # Orange
	else:
		boss_health_bar.modulate = Color(0.9, 0.3, 1.0)  # Purple
	
	# Hide bar when boss is dead
	if current <= 0:
		boss_health_bar.visible = false
		boss_health_label.visible = false

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_combo_changed(new_combo: int) -> void:
	if combo_label:
		if new_combo > 0:
			combo_label.text = "Combo: x%d" % new_combo
			combo_label.visible = true
			# Animate combo
			var tween := create_tween()
			tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
		else:
			combo_label.visible = false

extends CanvasLayer

@onready var mask_icons: HBoxContainer = %MaskIcons
@onready var hint_label: Label = %HintLabel
@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var exp_bar: ProgressBar = %EXPBar
@onready var exp_value_label: Label = %EXPValueLabel
@onready var level_label: Label = %LevelLabel
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
var mask_depleted_labels: Array[Label] = []  # Small "0" overlay on icon when depleted
var charge_labels: Array[Label] = []
## One entry per boss: { container: HBoxContainer, label: Label, bar: ProgressBar }
var boss_ui: Array = []
var pause_overlay: Control
var pause_menu_vbox: VBoxContainer
var pause_command_panel: Control
var pause_command_line: LineEdit
var pause_command_invalid_label: Label
var pause_resume_btn: Button
var pause_spend_row: HBoxContainer
var pause_spend_label: Label

func _ready() -> void:
	# Wait a frame for player to be ready
	await get_tree().process_frame
	_connect_to_player()
	_setup_mask_icons()
	_setup_charge_labels()
	_setup_pause_overlay()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		get_tree().paused = true
		pause_overlay.visible = true
		_show_pause_menu()
		get_viewport().set_input_as_handled()

func _setup_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.set_script(load("res://ui/PauseOverlay.gd"))
	add_child(pause_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.set_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)

	pause_menu_vbox = VBoxContainer.new()
	pause_menu_vbox.add_theme_constant_override("separation", 20)
	center.add_child(pause_menu_vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	pause_menu_vbox.add_child(title)

	pause_resume_btn = Button.new()
	pause_resume_btn.text = "Resume"
	pause_resume_btn.pressed.connect(_on_pause_resume)
	pause_menu_vbox.add_child(pause_resume_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Level"
	restart_btn.pressed.connect(_on_pause_restart)
	pause_menu_vbox.add_child(restart_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Quit to Title"
	quit_btn.pressed.connect(_on_pause_quit)
	pause_menu_vbox.add_child(quit_btn)

	var enter_cmd_btn := Button.new()
	enter_cmd_btn.text = "Debug Code"
	enter_cmd_btn.pressed.connect(_on_pause_enter_command)
	pause_menu_vbox.add_child(enter_cmd_btn)

	# Spend attribute point (shown in pause menu when unspent_points > 0)
	pause_spend_row = HBoxContainer.new()
	pause_spend_row.add_theme_constant_override("separation", 12)
	pause_spend_label = Label.new()
	pause_spend_label.text = "Spend point (0):"
	pause_spend_label.add_theme_font_size_override("font_size", 14)
	pause_spend_row.add_child(pause_spend_label)
	var pause_power_btn := Button.new()
	pause_power_btn.text = "+Power"
	pause_power_btn.pressed.connect(_on_spend_power)
	pause_spend_row.add_child(pause_power_btn)
	var pause_health_btn := Button.new()
	pause_health_btn.text = "+Health"
	pause_health_btn.pressed.connect(_on_spend_health)
	pause_spend_row.add_child(pause_health_btn)
	var pause_speed_btn := Button.new()
	pause_speed_btn.text = "+Speed"
	pause_speed_btn.pressed.connect(_on_spend_speed)
	pause_spend_row.add_child(pause_speed_btn)
	pause_spend_row.visible = false
	pause_menu_vbox.add_child(pause_spend_row)

	# Command entry panel (hidden by default)
	pause_command_panel = Control.new()
	pause_command_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_command_panel.set_offsets_preset(Control.PRESET_FULL_RECT)
	pause_command_panel.visible = false
	pause_command_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(pause_command_panel)

	var cmd_center := CenterContainer.new()
	cmd_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	cmd_center.set_offsets_preset(Control.PRESET_FULL_RECT)
	pause_command_panel.add_child(cmd_center)

	var cmd_vbox := VBoxContainer.new()
	cmd_vbox.add_theme_constant_override("separation", 12)
	cmd_vbox.custom_minimum_size = Vector2(320, 0)
	cmd_center.add_child(cmd_vbox)

	pause_command_line = LineEdit.new()
	pause_command_line.text_submitted.connect(_on_command_submitted)
	cmd_vbox.add_child(pause_command_line)

	var cmd_submit := Button.new()
	cmd_submit.text = "Run"
	cmd_submit.pressed.connect(_on_command_submit_clicked)
	cmd_vbox.add_child(cmd_submit)

	pause_command_invalid_label = Label.new()
	pause_command_invalid_label.text = "Invalid command!"
	pause_command_invalid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_command_invalid_label.add_theme_font_size_override("font_size", 14)
	pause_command_invalid_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	pause_command_invalid_label.visible = false
	cmd_vbox.add_child(pause_command_invalid_label)

func _show_pause_menu() -> void:
	pause_menu_vbox.visible = true
	pause_command_panel.visible = false
	pause_command_line.clear()
	pause_command_invalid_label.visible = false
	_update_pause_menu_spend_ui()
	pause_resume_btn.call_deferred("grab_focus")

func _on_pause_resume() -> void:
	get_tree().paused = false
	pause_overlay.visible = false

func _on_pause_restart() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	Game.restart_level()

func _on_pause_quit() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	get_tree().change_scene_to_file("res://main.tscn")

func _on_pause_enter_command() -> void:
	pause_menu_vbox.visible = false
	pause_command_panel.visible = true
	pause_command_line.clear()
	pause_command_invalid_label.visible = false
	pause_command_line.call_deferred("grab_focus")

func _on_command_submitted(_text: String) -> void:
	_run_command(pause_command_line.text)

func _on_command_submit_clicked() -> void:
	_run_command(pause_command_line.text)

func _run_command(raw: String) -> void:
	var text := raw.strip_edges().to_lower()
	# jumpToStage(N) -> load level_0N.tscn (N 1..6)
	var jump_regex := RegEx.new()
	jump_regex.compile("jumptostage\\s*\\(\\s*(\\d+)\\s*\\)")
	var jump_match := jump_regex.search(text)
	if jump_match:
		var n: int = int(jump_match.get_string(1))
		if n >= 1 and n <= 6:
			get_tree().paused = false
			pause_overlay.visible = false
			Game.load_level("res://level/level_%02d.tscn" % n)
			return
	pause_command_invalid_label.visible = true

func _hide_command_panel() -> void:
	pause_command_panel.visible = false
	pause_menu_vbox.visible = true
	pause_command_line.clear()
	pause_command_invalid_label.visible = false
	pause_resume_btn.call_deferred("grab_focus")

func close_command_panel_if_visible() -> bool:
	if pause_command_panel.visible:
		_hide_command_panel()
		return true
	return false

func _setup_mask_icons() -> void:
	# Collect mask icon nodes (Mask0, Mask1, etc.) and add depleted overlay labels
	for i in range(5):
		var icon := mask_icons.get_node("Mask" + str(i)) as ColorRect
		if icon:
			mask_icon_nodes.append(icon)
			var depleted_label := Label.new()
			depleted_label.name = "DepletedLabel"
			depleted_label.text = "0"
			depleted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			depleted_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			depleted_label.add_theme_font_size_override("font_size", 14)
			depleted_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			depleted_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			depleted_label.offset_left = 0
			depleted_label.offset_top = 0
			depleted_label.offset_right = 0
			depleted_label.offset_bottom = 0
			depleted_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			depleted_label.visible = false
			icon.add_child(depleted_label)
			mask_depleted_labels.append(depleted_label)

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
		mask_manager.charges_changed.connect(_on_charges_changed)
		ExperienceManager.exp_changed.connect(_on_exp_changed)
		ExperienceManager.level_up.connect(_on_level_up)
		ExperienceManager.stats_changed.connect(_on_exp_stats_changed)
		_on_exp_changed(ExperienceManager.exp_total, ExperienceManager.get_exp_to_next_level(), ExperienceManager.level)
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
	
	# Connect to all bosses (e.g. Level 3: 1 boss, Level 6: 2 bosses)
	var bosses := get_tree().get_nodes_in_group("bosses")
	boss_ui.clear()
	var boss_row := boss_health_bar.get_parent() as HBoxContainer
	var vbox := boss_row.get_parent() as VBoxContainer

	if bosses.is_empty():
		boss_row.visible = false
	else:
		for i in range(bosses.size()):
			var boss: Node = bosses[i]
			var label: Label
			var bar: ProgressBar
			var row_container: HBoxContainer
			if i == 0:
				boss_row.visible = true
				boss_health_label.text = "Boss 1:"
				boss_health_bar.visible = true
				boss_health_bar.max_value = boss.get("boss_health")
				boss_health_bar.value = boss.get("boss_health")
				label = boss_health_label
				bar = boss_health_bar
				row_container = boss_row
			else:
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				var l := Label.new()
				l.text = "Boss " + str(i + 1) + ":"
				l.add_theme_font_size_override("font_size", 12)
				l.add_theme_color_override("font_color", Color(0.9, 0.3, 1, 1))
				row.add_child(l)
				var b := ProgressBar.new()
				b.custom_minimum_size = Vector2(140, 12)
				b.max_value = boss.get("boss_health")
				b.value = boss.get("boss_health")
				b.show_percentage = false
				row.add_child(b)
				vbox.add_child(row)
				label = l
				bar = b
				row_container = row
			boss_ui.append({"container": row_container, "label": label, "bar": bar})

			if boss.has_signal("boss_health_changed"):
				var idx := i
				boss.boss_health_changed.connect(func(cur: int, max_h: int) -> void: _on_boss_health_changed_i(idx, cur, max_h))

func _on_mask_changed(mask: int) -> void:
	if not mask_manager:
		return
	
	hint_label.text = mask_manager.get_mask_hint()
	cooldown_bar.max_value = 3.0  # 3 seconds per mask
	cooldown_bar.value = 3.0  # Reset to full when mask changes
	
	# Update stats (switches)
	stats_label.text = "Switches: %d" % mask_manager.total_mask_switches
	# Level label
	level_label.text = "Lv.%d" % ExperienceManager.level
	
	# Highlight current mask, dim others; dim depleted (0 charges) even more and show "0"
	for i in range(mask_icon_nodes.size()):
		var icon := mask_icon_nodes[i]
		var charges: int = mask_manager.get_charges(i)
		var max_c: int = mask_manager.get_max_charges(i)
		var depleted: bool = max_c >= 0 and charges == 0
		_animate_icon_select(icon, i == mask, depleted, i)
	
	_update_all_charges()

func _animate_icon_select(icon: ColorRect, selected: bool, depleted: bool, icon_index: int) -> void:
	var tween := create_tween()
	var target_modulate: Color
	if depleted:
		target_modulate = Color(0.35, 0.35, 0.35, 0.65)  # Dim gray - exhausted
	else:
		target_modulate = Color.WHITE if selected else Color(0.6, 0.6, 0.6, 0.7)
	if selected:
		tween.tween_property(icon, "custom_minimum_size", Vector2(32, 32), 0.1)
		tween.parallel().tween_property(icon, "modulate", target_modulate, 0.1)
		icon.pivot_offset = icon.size / 2
	else:
		tween.tween_property(icon, "custom_minimum_size", Vector2(20, 20), 0.1)
		tween.parallel().tween_property(icon, "modulate", target_modulate, 0.1)
	# Show "0" overlay on icon when depleted
	if icon_index >= 0 and icon_index < mask_depleted_labels.size():
		mask_depleted_labels[icon_index].visible = depleted

func _on_cooldown_changed(remaining: float) -> void:
	cooldown_bar.value = remaining
	
	# Color based on time remaining (more urgent as time runs out)
	if remaining < 0.5:
		cooldown_bar.modulate = Color(1, 0.3, 0.3)  # Red - about to change
	elif remaining < 1.0:
		cooldown_bar.modulate = Color(1, 0.7, 0.3)  # Orange
	else:
		cooldown_bar.modulate = Color(0.3, 0.7, 1)  # Blue - plenty of time

func _on_exp_changed(_exp_total: int, exp_to_next: int, level: int) -> void:
	level_label.text = "Lv.%d" % level
	var to_next: int = max(1, exp_to_next)
	var current_seg: int = ExperienceManager.get_exp_in_current_segment()
	exp_bar.max_value = float(to_next)
	exp_bar.value = float(current_seg)
	exp_bar.modulate = Color(0.2, 0.8, 0.2)
	if exp_value_label:
		exp_value_label.text = "%d/%d" % [current_seg, to_next]

func _on_level_up(_new_level: int) -> void:
	_update_pause_menu_spend_ui()

func _on_exp_stats_changed() -> void:
	_update_pause_menu_spend_ui()

func _update_pause_menu_spend_ui() -> void:
	if not pause_spend_row:
		return
	if ExperienceManager.unspent_points <= 0:
		pause_spend_row.visible = false
		return
	pause_spend_row.visible = true
	pause_spend_label.text = "Spend point (%d):" % ExperienceManager.unspent_points

func _on_spend_power() -> void:
	if ExperienceManager.spend_point(&"power"):
		_apply_player_stats()
		_update_pause_menu_spend_ui()

func _on_spend_health() -> void:
	if ExperienceManager.spend_point(&"health"):
		_apply_player_stats()
		_update_pause_menu_spend_ui()

func _on_spend_speed() -> void:
	if ExperienceManager.spend_point(&"speed"):
		_apply_player_stats()
		_update_pause_menu_spend_ui()

func _apply_player_stats() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if not p:
		return
	p.max_health = ExperienceManager.get_max_health()
	p.health = min(p.health, p.max_health)
	p.health_changed.emit(p.health, p.max_health)
	p.speed = ExperienceManager.get_speed()
	if p.has_node("Sword"):
		p.get_node("Sword").damage = ExperienceManager.get_sword_damage()
	health_bar.max_value = p.max_health
	health_bar.value = p.health

func _on_charges_changed(mask: int, remaining: int) -> void:
	_update_charge_label(mask, remaining)

func _update_all_charges() -> void:
	if not mask_manager:
		return
	for i in range(charge_labels.size()):
		var charges: int = mask_manager.get_charges(i)
		_update_charge_label(i, charges)

func _update_mask_icon_appearance(icon_index: int) -> void:
	if not mask_manager or icon_index < 0 or icon_index >= mask_icon_nodes.size():
		return
	var icon: ColorRect = mask_icon_nodes[icon_index]
	var charges: int = mask_manager.get_charges(icon_index)
	var max_c: int = mask_manager.get_max_charges(icon_index)
	var is_depleted: bool = max_c >= 0 and charges == 0
	var is_current: bool = (mask_manager.current_mask == icon_index)
	var target_modulate: Color
	if is_depleted:
		target_modulate = Color(0.35, 0.35, 0.35, 0.65)
	else:
		target_modulate = Color.WHITE if is_current else Color(0.6, 0.6, 0.6, 0.7)
	icon.modulate = target_modulate
	icon.custom_minimum_size = Vector2(32, 32) if is_current else Vector2(20, 20)
	if icon_index < mask_depleted_labels.size():
		mask_depleted_labels[icon_index].visible = is_depleted

func _update_charge_label(mask: int, charges: int) -> void:
	if mask >= charge_labels.size():
		return
	var label := charge_labels[mask]
	if charges == -1:
		label.text = "∞"
		label.modulate = Color.WHITE
	elif charges == 0:
		label.text = "0"
		label.modulate = Color(0.9, 0.25, 0.25)  # Red - exhausted, obvious
	else:
		label.text = str(charges)
		label.modulate = Color.WHITE
	# Refresh icon appearance (dim + "0" overlay when depleted)
	_update_mask_icon_appearance(mask)

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

func _on_boss_health_changed_i(boss_index: int, current: int, max_health: int) -> void:
	if boss_index < 0 or boss_index >= boss_ui.size():
		return
	var ui: Dictionary = boss_ui[boss_index]
	var bar: ProgressBar = ui.bar
	var container: Control = ui.container
	bar.visible = true
	bar.max_value = max_health
	bar.value = current
	if current <= max_health * 0.3:
		bar.modulate = Color(1, 0.2, 0.2)
	elif current <= max_health * 0.6:
		bar.modulate = Color(1, 0.7, 0.2)
	else:
		bar.modulate = Color(0.9, 0.3, 1.0)
	if current <= 0:
		container.visible = false

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

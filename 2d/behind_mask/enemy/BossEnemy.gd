extends BaseEnemy
class_name BossEnemy

## Boss Enemy - Larger, more health, must be destroyed for exit door to appear

@export var boss_health := 10
@export var boss_scale := 3.5

signal boss_defeated

func _ready() -> void:
	super._ready()
	max_health = boss_health
	health = boss_health
	
	# Make boss larger
	visual.scale = Vector2(boss_scale, boss_scale)
	
	# Make detection circle larger
	detection_radius *= 1.5
	_draw_detection_circle()
	
	# Change boss to distinct purple/magenta color scheme
	_apply_boss_colors()
	
	# Enhanced visual - add boss indicator (positioned higher for larger boss)
	var boss_label := Label.new()
	boss_label.name = "BossLabel"
	boss_label.text = "BOSS"
	boss_label.position = Vector2(-50, -140)
	boss_label.add_theme_color_override("font_color", Color(0.9, 0.3, 1.0))
	boss_label.add_theme_font_size_override("font_size", 40)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(boss_label)
	
	# Health bar above boss (larger for bigger boss)
	var health_bar_bg := ColorRect.new()
	health_bar_bg.name = "HealthBarBG"
	health_bar_bg.position = Vector2(-60, -120)
	health_bar_bg.size = Vector2(120, 12)
	health_bar_bg.color = Color(0.2, 0.2, 0.2)
	add_child(health_bar_bg)
	
	var health_bar := ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(-60, -120)
	health_bar.size = Vector2(120, 12)
	health_bar.color = Color(0.8, 0.2, 1.0)
	health_bar_bg.add_child(health_bar)

func take_damage(amount: int) -> void:
	health -= amount
	health = max(0, health)
	
	# Update health bar
	var health_bar := get_node_or_null("HealthBarBG/HealthBar")
	if health_bar:
		var health_percent := float(health) / float(max_health)
		health_bar.size.x = 120.0 * health_percent
		health_bar.color = Color(lerp(0.3, 0.8, health_percent), lerp(0.1, 0.2, health_percent), lerp(0.5, 1.0, health_percent))
	
	# Visual feedback
	var flash_tween := create_tween()
	flash_tween.tween_property(visual, "modulate", Color(2, 0.5, 0.5, 1), 0.1)
	flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	
	# Damage number
	DamageNumber.create(global_position, amount)
	
	# Hit sparks
	ParticleManager.create_hit_sparks(global_position, Color(1, 0.2, 0.2))
	
	# Screen shake on boss hit
	Game.shake_camera(0.15, 0.2)
	
	if health <= 0:
		_die()

func _die() -> void:
	# Add score
	ScoreManager.add_kill_score("boss")
	
	# Emit signal before dying
	boss_defeated.emit()
	
	# Don't spawn regular enemies for boss
	# Create explosion effect
	_create_death_explosion()
	
	# Slow-mo on boss kill
	EffectManager.slow_mo(0.3, 0.2)
	
	queue_free()

func _apply_boss_colors() -> void:
	# Apply distinct purple/magenta color scheme to boss
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.4, 0.1, 0.6, 1)  # Dark purple shadow
	if body:
		body.color = Color(0.8, 0.2, 1.0, 1)  # Bright magenta
	if body_detail:
		body_detail.color = Color(0.9, 0.3, 1.0, 1)  # Lighter magenta
	if chest:
		chest.color = Color(0.7, 0.15, 0.9, 1)  # Purple chest
	if shoulder_left:
		shoulder_left.color = Color(0.6, 0.1, 0.8, 1)  # Darker purple
	if shoulder_right:
		shoulder_right.color = Color(0.6, 0.1, 0.8, 1)  # Darker purple
	
	# Change detection circle to purple
	detection_circle.color = Color(0.8, 0.2, 1.0, 0.15)

func _create_death_explosion() -> void:
	# Large explosion for boss with purple/magenta colors
	ParticleManager.create_explosion(global_position, 2.0, Color(0.8, 0.2, 1.0))

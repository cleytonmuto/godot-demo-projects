extends BaseEnemy
class_name BossEnemy

## Boss Enemy - Larger, more health, must be destroyed for exit door to appear

@export var boss_health := 100
@export var boss_scale := 3.5

signal boss_defeated
signal boss_health_changed(current: int, max_health: int)

func _ready() -> void:
	super._ready()
	max_health = boss_health
	health = boss_health
	
	# Mark this enemy as a boss so doors/logic can find it
	add_to_group("bosses")
	
	# Emit initial health state for HUD
	boss_health_changed.emit(health, max_health)
	
	# Make boss larger
	visual.scale = Vector2(boss_scale, boss_scale)
	
	# Make detection circle larger
	detection_radius *= 1.5
	_draw_detection_circle()
	
	# Change boss to distinct purple/magenta color scheme
	_apply_boss_colors()
	
func _draw() -> void:
	# Boss name above head (drawn to avoid Label strikethrough)
	var font := ThemeDB.fallback_font
	const FONT_SIZE := 40
	const BOSS_COLOR := Color(0.9, 0.3, 1.0)
	var text := "BOSS"
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TextServer.JUSTIFICATION_NONE)
	var ascent := font.get_ascent(FONT_SIZE)
	var pos := Vector2(-size.x / 2.0, -140.0 + ascent)
	font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, BOSS_COLOR, TextServer.JUSTIFICATION_NONE)

func take_damage(amount: int, hit_position: Vector2 = Vector2.ZERO) -> void:
	# Boss gets knockback too
	health -= amount
	health = max(0, health)
	
	# Apply knockback if hit position is provided
	if hit_position != Vector2.ZERO:
		var knockback_direction := (global_position - hit_position).normalized()
		if knockback_direction.length() < 0.1:
			if is_instance_valid(player):
				knockback_direction = (global_position - player.global_position).normalized()
			else:
				knockback_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		# Set knockback (boss is larger, so slightly less knockback force)
		knockback_velocity = knockback_direction * knockback_force * 0.7  # 70% of normal knockback
		is_knocked_back = true
		knockback_timer = knockback_duration
		
		# Visual knockback animation
		var tilt_tween := create_tween()
		var tilt_amount := knockback_direction.x * 0.15
		visual.rotation = tilt_amount
		tilt_tween.tween_property(visual, "rotation", 0.0, knockback_duration)
		
		var scale_tween := create_tween()
		var current_scale: Vector2 = visual.scale
		visual.scale = current_scale * 0.95
		scale_tween.tween_property(visual, "scale", current_scale, knockback_duration * 0.5)
	
	# Notify HUD about boss health change
	boss_health_changed.emit(health, max_health)
	
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
	ScoreManager.add_kill_score("boss")
	ExperienceManager.add_exp(max_health)
	# Emit signal before dying
	boss_defeated.emit()
	
	# Don't spawn regular enemies for boss
	# Create explosion effect
	_create_death_explosion()
	
	# 10% chance to drop a life potion (uses BaseEnemy.LIFE_POTION_* and _spawn_life_potion)
	if randf() < LIFE_POTION_DROP_CHANCE:
		_spawn_life_potion()
	
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

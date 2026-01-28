extends BaseEnemy
class_name IndigoEnemy

## Indigo Enemy - Takes 7 hits to eliminate

func _ready() -> void:
	super._ready()
	max_health = 7
	health = 7
	_apply_indigo_colors()

func _apply_indigo_colors() -> void:
	# Indigo color scheme
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.2, 0.1, 0.4, 1)  # Dark indigo shadow
	if body:
		body.color = Color(0.4, 0.2, 0.8, 1)  # Indigo
	if body_detail:
		body_detail.color = Color(0.5, 0.3, 0.9, 1)  # Light indigo
	if chest:
		chest.color = Color(0.35, 0.15, 0.7, 1)  # Darker indigo
	if shoulder_left:
		shoulder_left.color = Color(0.3, 0.1, 0.6, 1)  # Dark indigo
	if shoulder_right:
		shoulder_right.color = Color(0.3, 0.1, 0.6, 1)  # Dark indigo
	
	# Change detection circle to indigo
	detection_circle.color = Color(0.4, 0.2, 0.8, 0.08)

extends BaseEnemy
class_name VioletEnemy

## Violet Enemy - Takes 8 hits to eliminate

func _ready() -> void:
	super._ready()
	max_health = 80
	health = 8
	_apply_violet_colors()

func _apply_violet_colors() -> void:
	# Violet color scheme
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.4, 0.2, 0.5, 1)  # Dark violet shadow
	if body:
		body.color = Color(0.7, 0.3, 0.9, 1)  # Violet
	if body_detail:
		body_detail.color = Color(0.8, 0.4, 1, 1)  # Light violet
	if chest:
		chest.color = Color(0.6, 0.25, 0.8, 1)  # Darker violet
	if shoulder_left:
		shoulder_left.color = Color(0.5, 0.2, 0.7, 1)  # Dark violet
	if shoulder_right:
		shoulder_right.color = Color(0.5, 0.2, 0.7, 1)  # Dark violet
	
	# Change detection circle to violet
	detection_circle.color = Color(0.7, 0.3, 0.9, 0.08)

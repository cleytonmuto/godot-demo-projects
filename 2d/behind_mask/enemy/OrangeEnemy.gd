extends BaseEnemy
class_name OrangeEnemy

## Orange Enemy - Takes 3 hits to eliminate

func _ready() -> void:
	super._ready()
	max_health = 30
	health = 3
	_apply_orange_colors()

func _apply_orange_colors() -> void:
	# Orange color scheme
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.6, 0.3, 0.1, 1)  # Dark orange shadow
	if body:
		body.color = Color(1, 0.5, 0.2, 1)  # Orange
	if body_detail:
		body_detail.color = Color(1, 0.6, 0.3, 1)  # Light orange
	if chest:
		chest.color = Color(0.9, 0.45, 0.15, 1)  # Darker orange
	if shoulder_left:
		shoulder_left.color = Color(0.8, 0.4, 0.1, 1)  # Dark orange
	if shoulder_right:
		shoulder_right.color = Color(0.8, 0.4, 0.1, 1)  # Dark orange
	
	# Change detection circle to orange
	detection_circle.color = Color(1, 0.5, 0.2, 0.08)

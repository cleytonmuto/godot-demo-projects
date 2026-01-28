extends BaseEnemy
class_name BlueEnemy

## Blue Enemy - Takes 6 hits to eliminate

func _ready() -> void:
	super._ready()
	max_health = 6
	health = 6
	_apply_blue_colors()

func _apply_blue_colors() -> void:
	# Blue color scheme
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.1, 0.2, 0.5, 1)  # Dark blue shadow
	if body:
		body.color = Color(0.2, 0.4, 1, 1)  # Blue
	if body_detail:
		body_detail.color = Color(0.3, 0.5, 1, 1)  # Light blue
	if chest:
		chest.color = Color(0.15, 0.35, 0.9, 1)  # Darker blue
	if shoulder_left:
		shoulder_left.color = Color(0.1, 0.3, 0.7, 1)  # Dark blue
	if shoulder_right:
		shoulder_right.color = Color(0.1, 0.3, 0.7, 1)  # Dark blue
	
	# Change detection circle to blue
	detection_circle.color = Color(0.2, 0.4, 1, 0.08)

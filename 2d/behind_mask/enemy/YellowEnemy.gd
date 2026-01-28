extends BaseEnemy
class_name YellowEnemy

## Yellow Enemy - Takes 4 hits to eliminate

func _ready() -> void:
	super._ready()
	max_health = 4
	health = 4
	_apply_yellow_colors()

func _apply_yellow_colors() -> void:
	# Yellow color scheme
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.6, 0.5, 0.1, 1)  # Dark yellow shadow
	if body:
		body.color = Color(1, 0.9, 0.2, 1)  # Yellow
	if body_detail:
		body_detail.color = Color(1, 1, 0.4, 1)  # Light yellow
	if chest:
		chest.color = Color(0.9, 0.8, 0.15, 1)  # Darker yellow
	if shoulder_left:
		shoulder_left.color = Color(0.8, 0.7, 0.1, 1)  # Dark yellow
	if shoulder_right:
		shoulder_right.color = Color(0.8, 0.7, 0.1, 1)  # Dark yellow
	
	# Change detection circle to yellow
	detection_circle.color = Color(1, 0.9, 0.2, 0.08)

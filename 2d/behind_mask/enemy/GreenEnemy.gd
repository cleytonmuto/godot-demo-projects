extends BaseEnemy
class_name GreenEnemy

## Green Enemy - Takes 5 hits to eliminate

func _ready() -> void:
	super._ready()
	max_health = 5
	health = 5
	_apply_green_colors()

func _apply_green_colors() -> void:
	# Green color scheme
	var body_shadow := visual.get_node_or_null("BodyShadow")
	var body := visual.get_node_or_null("Body")
	var body_detail := visual.get_node_or_null("BodyDetail")
	var chest := visual.get_node_or_null("Chest")
	var shoulder_left := visual.get_node_or_null("ShoulderLeft")
	var shoulder_right := visual.get_node_or_null("ShoulderRight")
	
	if body_shadow:
		body_shadow.color = Color(0.1, 0.5, 0.2, 1)  # Dark green shadow
	if body:
		body.color = Color(0.2, 0.8, 0.3, 1)  # Green
	if body_detail:
		body_detail.color = Color(0.3, 0.9, 0.4, 1)  # Light green
	if chest:
		chest.color = Color(0.15, 0.7, 0.25, 1)  # Darker green
	if shoulder_left:
		shoulder_left.color = Color(0.1, 0.6, 0.2, 1)  # Dark green
	if shoulder_right:
		shoulder_right.color = Color(0.1, 0.6, 0.2, 1)  # Dark green
	
	# Change detection circle to green
	detection_circle.color = Color(0.2, 0.8, 0.3, 0.08)

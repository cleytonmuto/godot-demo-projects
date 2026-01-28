extends Node2D
class_name BackgroundGenerator

## Generates colorful, patterned backgrounds with shapes, forms, and textures

@export var color_scheme: int = 0  # 0=blue, 1=purple, 2=green, 3=pink, 4=factory, 5=office
@export var pattern_density: float = 1.0  # Multiplier for number of shapes
@export var level_width := 1024.0
@export var level_height := 768.0

const COLOR_SCHEMES := [
	# Blue scheme
	{
		"base": Color(0.15, 0.2, 0.35, 1),
		"accent1": Color(0.3, 0.5, 0.8, 0.6),
		"accent2": Color(0.5, 0.7, 1.0, 0.4),
		"accent3": Color(0.2, 0.4, 0.7, 0.5),
		"bright": Color(0.4, 0.6, 1.0, 0.3),
	},
	# Purple scheme
	{
		"base": Color(0.25, 0.15, 0.3, 1),
		"accent1": Color(0.5, 0.3, 0.7, 0.6),
		"accent2": Color(0.7, 0.4, 1.0, 0.4),
		"accent3": Color(0.4, 0.2, 0.6, 0.5),
		"bright": Color(0.6, 0.4, 0.9, 0.3),
	},
	# Green scheme
	{
		"base": Color(0.2, 0.3, 0.2, 1),
		"accent1": Color(0.3, 0.6, 0.4, 0.6),
		"accent2": Color(0.5, 0.8, 0.6, 0.4),
		"accent3": Color(0.25, 0.5, 0.3, 0.5),
		"bright": Color(0.4, 0.7, 0.5, 0.3),
	},
	# Pink scheme
	{
		"base": Color(0.35, 0.2, 0.25, 1),
		"accent1": Color(0.7, 0.4, 0.5, 0.6),
		"accent2": Color(1.0, 0.6, 0.7, 0.4),
		"accent3": Color(0.6, 0.3, 0.4, 0.5),
		"bright": Color(0.9, 0.5, 0.6, 0.3),
	},
	# Factory scheme
	{
		"base": Color(0.15, 0.15, 0.18, 1),
		"accent1": Color(0.4, 0.3, 0.2, 0.6),
		"accent2": Color(0.6, 0.4, 0.3, 0.4),
		"accent3": Color(0.3, 0.25, 0.2, 0.5),
		"bright": Color(0.8, 0.6, 0.4, 0.3),
	},
	# Office scheme
	{
		"base": Color(0.25, 0.25, 0.3, 1),
		"accent1": Color(0.4, 0.5, 0.6, 0.6),
		"accent2": Color(0.5, 0.6, 0.7, 0.4),
		"accent3": Color(0.3, 0.4, 0.5, 0.5),
		"bright": Color(0.6, 0.7, 0.8, 0.3),
	},
]

func _ready() -> void:
	_generate_background()

func _generate_background() -> void:
	var scheme = COLOR_SCHEMES[color_scheme % COLOR_SCHEMES.size()]
	
	# Base background
	var base := ColorRect.new()
	base.z_index = -10
	base.offset_right = level_width
	base.offset_bottom = level_height
	base.color = scheme.base
	add_child(base)
	
	# Gradient overlay
	var gradient := ColorRect.new()
	gradient.z_index = -9
	gradient.offset_right = level_width
	gradient.offset_bottom = level_height / 2.0
	gradient.color = scheme.accent1
	add_child(gradient)
	
	# Generate geometric shapes
	_generate_circles(scheme)
	_generate_triangles(scheme)
	_generate_rectangles(scheme)
	_generate_hexagons(scheme)
	_generate_stripes(scheme)
	_generate_grid_pattern(scheme)

func _generate_circles(scheme: Dictionary) -> void:
	var count := int(8 * pattern_density)
	for i in range(count):
		var circle := Polygon2D.new()
		circle.z_index = -8
		circle.color = scheme.accent2
		
		var radius := randf_range(30, 80)
		var center := Vector2(randf_range(0, level_width), randf_range(0, level_height))
		var points := PackedVector2Array()
		var segments := 16
		
		for j in range(segments):
			var angle := j * TAU / segments
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		
		circle.polygon = points
		add_child(circle)

func _generate_triangles(scheme: Dictionary) -> void:
	var count := int(12 * pattern_density)
	for i in range(count):
		var triangle := Polygon2D.new()
		triangle.z_index = -7
		triangle.color = scheme.accent3
		
		var size := randf_range(40, 100)
		var center := Vector2(randf_range(0, level_width), randf_range(0, level_height))
		var rotation := randf() * TAU
		
		var points := PackedVector2Array()
		for j in range(3):
			var angle := rotation + j * TAU / 3
			points.append(center + Vector2(cos(angle), sin(angle)) * size)
		
		triangle.polygon = points
		add_child(triangle)

func _generate_rectangles(scheme: Dictionary) -> void:
	var count := int(15 * pattern_density)
	for i in range(count):
		var rect := ColorRect.new()
		rect.z_index = -6
		rect.color = scheme.bright
		
		var width := randf_range(60, 150)
		var height := randf_range(60, 150)
		var center := Vector2(randf_range(0, level_width), randf_range(0, level_height))
		var rotation := randf() * TAU
		
		rect.position = center - Vector2(width / 2, height / 2)
		rect.offset_right = width
		rect.offset_bottom = height
		rect.pivot_offset = Vector2(width / 2, height / 2)
		rect.rotation = rotation
		add_child(rect)

func _generate_hexagons(scheme: Dictionary) -> void:
	var count := int(6 * pattern_density)
	for i in range(count):
		var hex := Polygon2D.new()
		hex.z_index = -5
		hex.color = scheme.accent1
		
		var radius := randf_range(35, 70)
		var center := Vector2(randf_range(0, level_width), randf_range(0, level_height))
		var points := PackedVector2Array()
		
		for j in range(6):
			var angle := j * TAU / 6
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		
		hex.polygon = points
		add_child(hex)

func _generate_stripes(scheme: Dictionary) -> void:
	# Diagonal stripes
	var stripe_count := int(20 * pattern_density)
	for i in range(stripe_count):
		var stripe := ColorRect.new()
		stripe.z_index = -4
		stripe.color = scheme.accent2
		
		var width := randf_range(3, 8)
		var length := randf_range(200, 400)
		var center := Vector2(randf_range(-200, 1224), randf_range(-200, 968))
		var angle := randf_range(-0.5, 0.5)  # Slight diagonal variation
		
		stripe.position = center - Vector2(length / 2, width / 2)
		stripe.offset_right = length
		stripe.offset_bottom = width
		stripe.pivot_offset = Vector2(length / 2, width / 2)
		stripe.rotation = angle
		add_child(stripe)

func _generate_grid_pattern(scheme: Dictionary) -> void:
	# Create a subtle grid overlay
	var grid_lines := int(15 * pattern_density)
	
	# Vertical lines
	for i in range(grid_lines):
		var line := ColorRect.new()
		line.z_index = -3
		line.color = scheme.accent3
		line.offset_right = 1.0
		line.offset_bottom = level_height
		line.position = Vector2(randf_range(0, level_width), 0)
		add_child(line)
	
	# Horizontal lines
	for i in range(grid_lines):
		var line := ColorRect.new()
		line.z_index = -3
		line.color = scheme.accent3
		line.offset_right = level_width
		line.offset_bottom = 1.0
		line.position = Vector2(0, randf_range(0, level_height))
		add_child(line)

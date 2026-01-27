extends RefCounted
class_name PixelArtGenerator

## Utility class for generating pixel art style textures procedurally

static func create_pixel_texture(size: Vector2i, colors: Array[Color], pattern: String = "solid") -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	match pattern:
		"solid":
			image.fill(colors[0] if colors.size() > 0 else Color.WHITE)
		"checker":
			for y in range(size.y):
				for x in range(size.x):
					var idx := (x + y) % colors.size()
					image.set_pixel(x, y, colors[idx])
		"gradient_h":
			for x in range(size.x):
				var t := float(x) / float(size.x)
				var color := colors[0].lerp(colors[1] if colors.size() > 1 else colors[0], t)
				for y in range(size.y):
					image.set_pixel(x, y, color)
		"gradient_v":
			for y in range(size.y):
				var t := float(y) / float(size.y)
				var color := colors[0].lerp(colors[1] if colors.size() > 1 else colors[0], t)
				for x in range(size.x):
					image.set_pixel(x, y, color)
		"stripes_h":
			for y in range(size.y):
				var stripe := int(y / 4) % colors.size()
				for x in range(size.x):
					image.set_pixel(x, y, colors[stripe])
		"stripes_v":
			for x in range(size.x):
				var stripe := int(x / 4) % colors.size()
				for y in range(size.y):
					image.set_pixel(x, y, colors[stripe])
	
	var texture := ImageTexture.new()
	texture.set_image(image)
	texture.set_filter(ImageTexture.FILTER_NEAREST)  # Pixel perfect
	return texture

static func create_mask_sprite(mask_type: int, size: Vector2i = Vector2i(32, 32)) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	# Base mask colors
	var mask_colors := {
		0: Color.WHITE,  # NEUTRAL
		1: Color(0.4, 0.6, 1.0),  # GUARD - Blue
		2: Color(0.7, 0.7, 0.7, 0.5),  # GHOST - Gray transparent
		3: Color(1.0, 0.3, 0.3),  # PREDATOR - Red
		4: Color(1.0, 0.9, 0.3),  # DECOY - Yellow
	}
	
	var base_color := mask_colors.get(mask_type, Color.WHITE)
	
	# Draw mask shape (simplified pixel art)
	var center_x := size.x / 2
	var center_y := size.y / 2
	
	# Fill with base color
	image.fill(base_color)
	
	# Add mask details
	for y in range(size.y):
		for x in range(size.x):
			var dist_from_center := Vector2(x - center_x, y - center_y).length()
			
			# Mask outline (darker)
			if dist_from_center > size.x / 2 - 2 and dist_from_center < size.x / 2:
				image.set_pixel(x, y, base_color.darkened(0.3))
			
			# Eye holes
			if (x - center_x + 4) * (x - center_x + 4) + (y - center_y + 2) * (y - center_y + 2) < 16:
				image.set_pixel(x, y, Color(0.1, 0.1, 0.1))
			if (x - center_x - 4) * (x - center_x - 4) + (y - center_y + 2) * (y - center_y + 2) < 16:
				image.set_pixel(x, y, Color(0.1, 0.1, 0.1))
	
	var texture := ImageTexture.new()
	texture.set_image(image)
	texture.set_filter(ImageTexture.FILTER_NEAREST)
	return texture

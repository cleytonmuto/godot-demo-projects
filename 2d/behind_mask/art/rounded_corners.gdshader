shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 0.5) = 0.25;

void fragment() {
	vec2 uv = UV;
	float r = corner_radius;
	// Top-left corner
	if (uv.x < r && uv.y < r) {
		if (distance(uv, vec2(r, r)) > r) {
			COLOR.a = 0.0;
			return;
		}
	}
	// Top-right corner
	else if (uv.x > 1.0 - r && uv.y < r) {
		if (distance(uv, vec2(1.0 - r, r)) > r) {
			COLOR.a = 0.0;
			return;
		}
	}
	// Bottom-left corner
	else if (uv.x < r && uv.y > 1.0 - r) {
		if (distance(uv, vec2(r, 1.0 - r)) > r) {
			COLOR.a = 0.0;
			return;
		}
	}
	// Bottom-right corner
	else if (uv.x > 1.0 - r && uv.y > 1.0 - r) {
		if (distance(uv, vec2(1.0 - r, 1.0 - r)) > r) {
			COLOR.a = 0.0;
			return;
		}
	}
}

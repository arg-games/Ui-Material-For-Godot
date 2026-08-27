shader_type canvas_item;
render_mode unshaded;

#include "res://addons/ui_material/ui_material.gdshaderinc"

uniform int test_mode : hint_range(0, 4, 1) = 0;
uniform bool keep_aspect_ratio = true;

void fragment() {
	vec3 color = vec3(0.0);
	float alpha = 0.0;

	if (test_mode == 0 || test_mode == 4) {
		sdf_shape_result box = sdf_box(
				UV,
				vec2(0.38),
				0.0,
				0.006,
				vec4(0.12),
				0.0,
				true,
				0.0,
				keep_aspect_ratio
		);
		color = test_mode == 4 ? vec3(0.95, 0.36, 0.24) : vec3(0.24, 0.72, 0.98);
		alpha = box.fill;
	} else if (test_mode == 1) {
		vec2 corrected_uv = uv_aspect_correct(UV);
		sdf_shape_result circle = sdf_circle(
				corrected_uv,
				0.72,
				0.0,
				0.006,
				0.0,
				false
		);
		color = vec3(0.98, 0.78, 0.25);
		alpha = circle.fill;
	} else if (test_mode == 2) {
		pattern_result grid = pattern(UV, vec2(6.0, 3.0));
		sdf_shape_result dot = sdf_circle(
				grid.scaled_pattern_uvs,
				0.34,
				0.0,
				0.02,
				0.0,
				false
		);
		color = vec3(0.40, 0.92, 0.62);
		alpha = dot.fill;
	} else {
		halftone_result dots = halftone(
				UV,
				0.5,
				18.0,
				0.05,
				0.35,
				0.0,
				0.02,
				vec2(0.0),
				0.0,
				TIME
		);
		color = vec3(0.90, 0.42, 0.84);
		alpha = dots.fill;
	}

	COLOR = vec4(color, alpha);
}

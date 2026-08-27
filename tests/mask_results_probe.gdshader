shader_type canvas_item;
render_mode unshaded;

#include "res://addons/ui_material/ui_material.gdshaderinc"

void fragment() {
	alternate_mask_result alternate = uv_alternate_mask(UV, uint(4));
	alternate_mask_result default_alternate = uv_alternate_mask(UV);
	blind_mask_result blind = uv_blind_mask(UV, 0.0, 0.5, 2.0, 0.02);
	blind_mask_result default_blind = uv_blind_mask(UV);
	wedges_mask_result wedges = uv_wedges_mask(UV);
	float square = square_gradient(UV);

	float alternate_value = alternate.rows
			+ alternate.columns
			+ default_alternate.rows
			+ default_alternate.columns;
	float blind_value = fract(abs(blind.raw_mask))
			+ blind.one_sided
			+ blind.symmetrical
			+ fract(abs(default_blind.raw_mask))
			+ default_blind.one_sided
			+ default_blind.symmetrical;
	float wedges_value = wedges.subdivision_1
			+ wedges.subdivision_2
			+ wedges.subdivision_3;

	COLOR = vec4(
			fract(alternate_value * 0.25),
			fract(blind_value * 0.125),
			fract(wedges_value * 0.25),
			square
	);
}

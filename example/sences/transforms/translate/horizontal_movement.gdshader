shader_type canvas_item;

#include "res://addons/ui_material/ui_material.gdshaderinc"

uniform float movement_speed = 0.5;
uniform int movement_type : hint_enum("Horizontal", "Vertical") = 0;

void fragment() {
    float ping_pong_animation = ping_pong_0_1(TIME, movement_speed);

    vec2 horizontal_movement = vec2(mix(-0.25, 0.25, ping_pong_animation), 0);
	vec2 vertical_movement = vec2(0, mix(-0.25, 0.25, ping_pong_animation));
	
	vec2 final_movement = (movement_type == 0) ? horizontal_movement : vertical_movement;
    vec2 translated_uv = uv_translate_raw(UV, final_movement);

    sdf_shape_result shape = sdf_box(translated_uv, vec2(0.5, 0.5), 0.0, 0.01, vec4(0.0), 0.1, true, 0.0, true);

    COLOR = vec4(vec3(1.0), shape.fill);
}

#include "time.gdshaderinc"

struct polar_coordinates_result
{
	vec2 radial_coordinates;
	float angle_gradient;
};

struct wave_warp_result
{
	vec2 warped_uvs;
	vec2 raw_distortion;
};

/* Converts a centered vector or UV into canonical polar coordinates.
 * radial_coordinates is ordered as (radius, angle). The angle is also
 * exposed as the angle_gradient output of Polar Coordinates.
 *
 * 把以 0.5 为中心的向量或 UV 转为极坐标。
 * radial_coordinates 固定为 (radius, angle) 顺序。
 * angle_gradient 对应 Polar Coordinates 的 Angle gradient 输出。 */
polar_coordinates_result polar_coordinates(vec2 value_or_uv) {
	vec2 centered = vec2(0.5) - value_or_uv;

	polar_coordinates_result result;
	result.angle_gradient = fract(atan(centered.x, centered.y) / TAU);
	result.radial_coordinates = vec2(length(centered), result.angle_gradient);

	return result;
}

/* Fakes a perspective rotation by rotating UVs around the center of the
 * unit square, then scaling them by their rotated X. Matches the
 * Skewed UVs output of Skew.
 *
 * 绕单位方形中心旋转 UV，再按旋转后的 X 值缩放，模拟透视式转动。
 * 对应 Skew 的 Skewed UVs 输出。 */
vec2 uv_skew(vec2 uv, float skew_rotation, float skew_amount) {
	vec2 center = vec2(0.5);
	float angle = skew_rotation * TAU;
	float sine = sin(angle);
	float cosine = cos(angle);
	vec2 offset = uv - center;
	vec2 rotated = vec2(
			offset.x * cosine - offset.y * sine,
			offset.x * sine + offset.y * cosine
	) + center;
	float scale = mix(1.0, rotated.x, skew_amount);

	return (uv - center) * scale + center;
}

vec2 uv_skew(vec2 uv) {
	return uv_skew(uv, 0.0, 0.4);
}

/* Skews the UVs like uv_skew, then builds a soft alpha mask from the
 * shortest distance to the four transformed edges. alpha_threshold sets
 * where the mask starts and alpha_feather sets its softness. Matches
 * the Alpha mask output of Skew.
 *
 * 先按 uv_skew 变形 UV，再依据到四条变形边的最短距离生成柔和的 alpha 遮罩。
 * alpha_threshold 控制遮罩起始位置，alpha_feather 控制柔边宽度。
 * 对应 Skew 的 Alpha mask 输出。 */
float uv_alpha_mask(
		vec2 uv,
		float skew_rotation,
		float skew_amount,
		float alpha_threshold,
		float alpha_feather) {
	vec2 skewed_uv = uv_skew(uv, skew_rotation, skew_amount);
	vec2 opposite = vec2(1.0) - skewed_uv;
	float edge_distance = min(
			min(skewed_uv.x, skewed_uv.y),
			min(opposite.x, opposite.y)
	);

	return smoothstep(alpha_threshold, alpha_threshold + alpha_feather, edge_distance);
}

float uv_alpha_mask(vec2 uv, float alpha_threshold, float alpha_feather) {
	return uv_alpha_mask(uv, 0.0, 0.4, alpha_threshold, alpha_feather);
}

float uv_alpha_mask(vec2 uv) {
	return uv_alpha_mask(uv, 0.0, 0.4, 0.0, 0.02);
}

/* Slants the coordinates horizontally and vertically by slant_amount
 * while keeping the center fixed. Matches Slant.
 *
 * 按 slant_amount 对两轴做斜切，中心保持不动。对应 Slant。 */
vec2 uv_slant(vec2 uv, vec2 slant_amount) {
	vec2 slant = vec2(uv.y * slant_amount.x, uv.x * slant_amount.y);

	return uv + slant - slant_amount * 0.5;
}

vec2 uv_slant(vec2 uv) {
	return uv_slant(uv, vec2(0.25, 0.0));
}

/* Applies Wave Warp and returns both the warped coordinates and the raw
 * displacement. Matches the Warped UVs and Raw distortion outputs.
 *
 * 应用 Wave Warp，并同时返回变形后的坐标与原始位移。
 * 对应 Wave Warp 的 Warped UVs 与 Raw distortion 输出。 */
wave_warp_result uv_wave_warp(
		vec2 uv,
		float phase,
		float motion,
		float frequency_x,
		float frequency_y,
		float amplitude_x,
		float amplitude_y) {
	float time_offset = phase + motion;
	float wave_x = sin((uv.x * frequency_x + time_offset) * TAU);
	float wave_y = sin((uv.y * frequency_y + time_offset) * TAU);

	wave_warp_result result;
	result.raw_distortion = vec2(
			wave_x * amplitude_x,
			wave_y * amplitude_y
	);
	result.warped_uvs = uv + result.raw_distortion;

	return result;
}

wave_warp_result uv_wave_warp(vec2 uv) {
	return uv_wave_warp(uv, 0.0, loop_0_1(0.3), 5.0, 5.0, 0.07, 0.05);
}

// UV transform functions converted from the UE material functions.

/* Flips the coordinates horizontally. Flipping is relative to the input
 * coordinates, not the container, so content mirrors around itself.
 * Matches the Mirror X output of Flip.
 *
 * 水平翻转坐标。翻转相对输入坐标而非容器，内容原地镜像。
 * 对应 Flip 的 Mirror X 输出。 */
vec2 uv_mirror_x(vec2 uv) {
	return vec2(1.0 - uv.x, uv.y);
}

/* Flips the coordinates vertically. Matches the Mirror Y output of
 * Flip.
 *
 * 垂直翻转坐标。对应 Flip 的 Mirror Y 输出。 */
vec2 uv_mirror_y(vec2 uv) {
	return vec2(uv.x, 1.0 - uv.y);
}

/* Flips both coordinates at once. Matches the Mirror X and Y output of
 * Flip.
 *
 * 两轴同时翻转。对应 Flip 的 Mirror X and Y 输出。 */
vec2 uv_mirror_xy(vec2 uv) {
	return vec2(1.0) - uv;
}

/* Scales the coordinate space around scale_center. Scaling is relative
 * to the input coordinates, so content translated elsewhere keeps
 * scaling around its own position. Values near zero clamp to 0.001 to
 * avoid division blowups. Matches Scale.
 *
 * 以 scale_center 为中心缩放坐标空间。缩放相对输入坐标，
 * 已平移的内容仍绕自身位置缩放。
 * 接近零的值钳制到 0.001，避免除法数值失控。
 * 对应 Scale 材质函数。 */
vec2 uv_scale(vec2 uv, vec2 scale_center, vec2 scale) {
	vec2 safe_scale = max(scale, vec2(0.001));
	return (uv - scale_center) / safe_scale + scale_center;
}

vec2 uv_scale(vec2 uv) {
	return uv_scale(uv, vec2(0.5), vec2(0.5));
}

/* Translates the coordinate space without clamping the range. The
 * horizontal axis is inverted so positive translate.x moves right,
 * matching Translate's user-facing convention.
 *
 * 平移坐标空间且不限制范围。
 * 水平方向做了反转，translate.x 为正时向右移动，与 Translate 的操作习惯一致。
 * 对应 Translate 的 UVs raw 输出。 */
vec2 uv_translate_raw(vec2 uv, vec2 translate) {
	return uv + vec2(-translate.x, translate.y);
}

vec2 uv_translate_raw(vec2 uv) {
	return uv_translate_raw(uv, vec2(0.0));
}

/* Same translation as uv_translate_raw, wrapped back into 0..1 with
 * fract so content tiles. Matches the UVs repeat output of Translate.
 *
 * 平移方式与 uv_translate_raw 相同，结果经 fract 包回 0 到 1，内容因此平铺。
 * 对应 Translate 的 UVs repeat 输出。 */
vec2 uv_translate_repeat(vec2 uv, vec2 translate) {
	return fract(uv_translate_raw(uv, translate));
}

vec2 uv_translate_repeat(vec2 uv) {
	return uv_translate_repeat(uv, vec2(0.0));
}

struct symmetry_result
{
	vec2 symmetric_uv;
	float right_side_mask;
	float left_side_mask;
};

/* Mirrors the coordinates across the chosen axis, rotates and scales the
 * result, then returns all outputs of Symmetry. symmetry_axis floors to 0
 * or 1: 0 mirrors horizontally across the vertical axis, 1 vertically
 * across the horizontal axis. flip_other_axis_too mirrors the other
 * coordinate as well. The side masks describe the mirror split before
 * rotation and scale.
 *
 * 沿选定轴镜像坐标，再旋转和缩放结果，最后返回 Symmetry 的全部输出。
 * symmetry_axis 向下取整后，0 表示沿纵轴的水平镜像，1 表示沿横轴的垂直镜像。
 * flip_other_axis_too 决定另一坐标是否同时镜像。
 * 侧向遮罩描述旋转和缩放前的镜像分区。 */
symmetry_result uv_symmetry(
		vec2 uv,
		float symmetry_axis,
		vec2 offset,
		bool flip_other_axis_too,
		float rotation,
		vec2 scale) {
	float axis = floor(symmetry_axis);
	vec2 tiling = mix(vec2(1.0, 2.0), vec2(2.0, 1.0), axis);
	vec2 scaled_uv = uv * tiling;
	vec2 base_uv = fract(scaled_uv) + offset;
	vec2 mirrored_uv = vec2(1.0) - base_uv + 2.0 * offset;
	vec2 flip_x = vec2(mirrored_uv.x, base_uv.y);
	vec2 flip_y = vec2(base_uv.x, mirrored_uv.y);
	vec2 axis_zero = flip_other_axis_too ? flip_y : flip_x;
	vec2 axis_one = flip_other_axis_too ? flip_x : flip_y;

	float right_side_mask = clamp(
			floor(mix(scaled_uv.y, scaled_uv.x, axis)),
			0.0,
			1.0
	);

	vec2 symmetric_uv = mix(
			base_uv,
			mix(axis_zero, axis_one, axis),
			right_side_mask
	);

	symmetry_result result;
	result.symmetric_uv = symmetric_uv;
	result.right_side_mask = right_side_mask;
	result.left_side_mask = 1.0 - right_side_mask;

	float angle = rotation * TAU;
	float sine = sin(angle);
	float cosine = cos(angle);
	vec2 centered_uv = result.symmetric_uv - vec2(0.5);
	vec2 rotated_uv = vec2(
			centered_uv.x * cosine - centered_uv.y * sine,
			centered_uv.x * sine + centered_uv.y * cosine
	) + vec2(0.5);

	result.symmetric_uv = uv_scale(rotated_uv, vec2(0.5), scale);

	return result;
}

symmetry_result uv_symmetry(vec2 uv) {
	return uv_symmetry(uv, 1.0, vec2(0.0), true, 0.0, vec2(1.0));
}

// Mask functions converted from the UE material functions.

#include "distortion.gdshaderinc"
#include "utilities/ping_pong.gdshaderinc"
#include "sdf/sdf_circle.gdshaderinc"

struct radial_segments_result
{
	float triangles;
	float lines;
};

struct sectors_result
{
	float sectors;
	float raw_mask;
};

/* Alternates 0 and 1 between cell rows along Y. num_steps sets how many
 * rows tile the height.
 *
 * 沿 Y 方向逐行交替输出 0 和 1。num_steps 决定纵向格子数量。 */
float alternate_rows_mask(vec2 uv, uint num_steps) {
	float step_count = float(num_steps);
	return abs(mod(floor(uv * step_count).y, 2.0));
}

float alternate_rows_mask(vec2 uv) {
	return alternate_rows_mask(uv, uint(4));
}

/* Alternates 0 and 1 between cell columns along X. num_steps sets how
 * many columns tile the width.
 *
 * 沿 X 方向逐列交替输出 0 和 1。num_steps 决定横向格子数量。 */
float alternate_columns_mask(vec2 uv, uint num_steps) {
	float step_count = float(num_steps);
	return abs(mod(floor(uv * step_count).x, 2.0));
}

float alternate_columns_mask(vec2 uv) {
	return alternate_columns_mask(uv, uint(4));
}

/* Unclamped blind stripes forming a single gradient that exceeds 1,
 * ready for custom remapping such as sine-driven progress. rotation
 * turns the stripe direction and tiling sets the stripe count. Matches
 * the Raw mask unclamped output of Blind Mask.
 *
 * 输出未钳制的百叶窗条纹，呈超过 1 的单向渐变，适合再做自定义映射，例如正弦进度。
 * rotation 转动条纹方向，tiling 设定条纹数量。
 * 对应 Blind Mask 的 Raw mask unclamped 输出。 */
float blind_mask_raw(vec2 uv, float rotation, float tiling) {
	vec2 offset = uv - vec2(0.5);
	float angle = rotation * TAU;
	float sine = sin(angle);
	float cosine = cos(angle);
	vec2 rotated_uv = vec2(
			offset.x * cosine - offset.y * sine,
			offset.x * sine + offset.y * cosine
	) + vec2(0.5);

	return rotated_uv.x * tiling;
}

float blind_mask_raw(vec2 uv) {
	return blind_mask_raw(uv, 0.0, 2.0);
}

/* Blind stripes expanding from one side. progress opens the blinds:
 * 0 keeps them closed (white) and 1 fully open (black). Higher feather
 * values soften edges. Matches the One-sided output of Blind Mask.
 *
 * 百叶窗条纹从一侧展开。progress 控制开合：0 全闭（白），1 全开（黑）。
 * feather 越大边缘越柔。对应 Blind Mask 的 One-sided 输出。 */
float blind_mask_one_sided(
		vec2 uv,
		float rotation,
		float progress,
		float tiling,
		float feather) {
	float raw = blind_mask_raw(uv, rotation, tiling);
	return smoothstep(progress, progress + feather, fract(raw));
}

float blind_mask_one_sided(vec2 uv) {
	return blind_mask_one_sided(uv, 0.0, 0.5, 2.0, 0.02);
}

/* Blind stripes expanding outward from the center. Parameters match
 * blind_mask_one_sided. Matches the Symmetrical output of Blind Mask.
 *
 * 百叶窗条纹从中心向两侧展开。参数与 blind_mask_one_sided 相同。
 * 对应 Blind Mask 的 Symmetrical 输出。 */
float blind_mask_symmetrical(
		vec2 uv,
		float rotation,
		float progress,
	float tiling,
	float feather) {
	float raw = blind_mask_raw(uv, rotation, tiling);
	return smoothstep(
			progress,
			progress + feather,
			ping_pong(raw, 1.0, 1.0).result
	);
}

float blind_mask_symmetrical(vec2 uv) {
	return blind_mask_symmetrical(uv, 0.0, 0.5, 2.0, 0.02);
}

/* Checkered mask alternating per cell. subdivisions counts rows and
 * columns before the doubling applied here, keeping the UE graph
 * behavior. Pairs well with grid patterns to alternate values per cell.
 * Matches Checker Mask.
 *
 * 逐格交替的棋盘格遮罩。subdivisions 为加倍前的行列数，此处保留 UE 图的加倍行为。
 * 适合与网格类图案搭配做逐格交替。对应 Checker Mask。 */
float checkerboard_mask(vec2 uv, vec2 subdivisions) {
	vec2 cell = floor(uv * subdivisions * 2.0);
	return mod(cell.x + cell.y, 2.0);
}

float checkerboard_mask(vec2 uv) {
	return checkerboard_mask(uv, vec2(4.0));
}

/* Concentric sine rings sharpened through glow_min_max.
 * keep_inside_bounds clips everything beyond the container circle.
 *
 * 同心正弦环纹经 glow_min_max 锐化。
 * keep_inside_bounds 为 true 时裁剪容器圆以外的部分。 */
float radial_glow_mask(
		vec2 uv,
		float subdivisions,
		vec2 glow_min_max,
		bool keep_inside_bounds) {
	float radius = length((uv - vec2(0.5)) * 2.0);
	float wave = sin(radius * subdivisions * TAU) * 0.5 + 0.5;
	float glow = smoothstep(glow_min_max.x, glow_min_max.y, wave);
	float inside = min(glow, ceil(1.0 - radius));

	return keep_inside_bounds ? inside : glow;
}

float radial_glow_mask(vec2 uv) {
	return radial_glow_mask(uv, 3.0, vec2(0.51, 0.49), false);
}

/* Splits the plane radially into beams around the center. Returns
 * (segmented triangles, segmented lines): triangles converge toward the
 * center while lines keep constant thickness. subdivisions sets the
 * beam count, segment_spacing the gap, feather the softness. Pairs
 * well with the sdf_circle outline for segmented progress bars. Matches
 * Radial Segments.
 *
 * 把平面沿径向分成围绕中心的束条。返回 (三角束, 线束) 两个分量：
 * 三角束向中心汇聚，线束保持恒定宽度。
 * subdivisions 设束数，segment_spacing 设间隙，feather 设柔边。
 * 与 sdf_circle 的 outline 组合可做环形分段进度条。对应 Radial Segments。 */
radial_segments_result radial_segments(
		vec2 uv,
		float segment_spacing,
		float feather,
		float subdivisions) {
	float angle = polar_coordinates(uv).angle_gradient;
	float triangle_wave = ping_pong(
			angle * floor(subdivisions),
			1.0,
			1.0
	).result;
	float inverse_triangle = 1.0 - triangle_wave;
	float triangles = smoothstep(
			segment_spacing,
			segment_spacing + feather,
			inverse_triangle
	);

	float radius = length(uv - vec2(0.5));
	float line_value = clamp(triangle_wave * radius, 0.0, 1.0);
	float lines = smoothstep(
			segment_spacing,
			segment_spacing + feather,
			1.0 - 2.0 * line_value
	);

	radial_segments_result result;
	result.triangles = triangles;
	result.lines = lines;

	return result;
}

radial_segments_result radial_segments(vec2 uv) {
	return radial_segments(uv, 0.8, 0.002, 5.0);
}

/* Alternating concentric rings with an integer subdivision count.
 * glow_min_max sharpens ring falloff the same way SDF glow does.
 * keep_inside_bounds clips beyond the container circle. Matches Ring
 * Mask.
 *
 * 按整数细分数生成同心环纹。
 * glow_min_max 以 SDF 同款方式控制环的软硬，keep_inside_bounds 裁剪容器圆以外的部分。
 * 对应 Ring Mask。 */
float ring_mask(vec2 uv, vec2 glow_minmax, int subdivisions, bool keep_inside_bounds) {
	float radius = length((uv - vec2(0.5)) * 2.0);
	float wave = abs(sin(TAU * radius * float(subdivisions)) * 0.5 + 0.5);

	float result = smoothstep(glow_minmax.x, glow_minmax.y, wave);

	if (keep_inside_bounds) {
		return min(result, ceil(1.0 - radius));
	}

	return result;
}

/* Sector waves multiplied by a circle outline, suited for loading
 * spinners and throbbers. Returns sectors and raw_mask together:
 * sectors combines the circle outline with the wave, raw_mask is the wave
 * alone. radius, sharpness and thickness shape only the circle part.
 *
 * 扇区波纹与圆形描边相乘，适合加载指示动画。
 * 返回 (扇区, 原始遮罩) 两个分量：前者含圆形描边，后者不含。
 * radius、sharpness、thickness 只作用于圆形部分。对应 Sectors。 */
sectors_result sectors(
		vec2 uv,
		float subdivisions,
		float radius,
		float sharpness,
		float thickness,
		float contrast,
		float motion,
		bool is_symmetrical) {
	float angle = polar_coordinates(uv).angle_gradient;
	float animated = angle * subdivisions - motion;
	float wave = is_symmetrical
			? ping_pong(animated, 1.0, 1.0).result
			: fract(animated);
	float raw_mask = pow(wave, contrast);

	sdf_shape_result circle = sdf_circle(uv, radius, 0.0, 1.0 - sharpness, thickness, false);

	sectors_result result;
	result.sectors = circle.outline * raw_mask;
	result.raw_mask = raw_mask;

	return result;
}

sectors_result sectors(vec2 uv) {
	return sectors(uv, 4.0, 0.8, 0.97, 0.05, 4.0, loop_0_1(0.2), false);
}

/* Diagonal wedge masks matching MF_UI_WedgesMask. wedges_mask_1 splits
 * the plane into two triangles along the main diagonal.
 *
 * 对角楔形遮罩，对应 MF_UI_WedgesMask。
 * wedges_mask_1 沿主对角线把平面分成两个三角形。 */
float wedges_mask_1(vec2 uv) {
	return ceil(uv.y - uv.x);
}

/* Four triangles arranged in an hourglass shape, built by differencing
 * the two diagonals.
 *
 * 两条对角线相减得到沙漏状的四个三角形区域。 */
float wedges_mask_2(vec2 uv) {
	float diagonal_1 = wedges_mask_1(uv);
	float diagonal_2 = ceil(uv.y - (1.0 - uv.x));

	return 1.0 - max(
			clamp(diagonal_2 - diagonal_1, 0.0, 1.0),
			clamp(diagonal_1 - diagonal_2, 0.0, 1.0)
	);
}

/* Eight triangles built by checkerboarding wedges_mask_2 per half.
 *
 * 用棋盘格对 wedges_mask_2 分半交替，得到八个三角形区域。 */
float wedges_mask_3(vec2 uv) {
	float hourglass = wedges_mask_2(uv);

	return mix(1.0 - hourglass, hourglass, checkerboard_mask(uv, vec2(1.0)));
}

/* Square-space angular gradient built from four diagonal wedges remapped
 * to quarter ranges and combined with max. Combine with an SDF box
 * outline to shade around a square frame. Matches Square Gradient.
 *
 * 方形空间的角度渐变：四块对角楔形各自重映射到四分之一区间后取最大值合并。
 * 与 SDF 方框描边组合可做方框周围的着色。对应 Square Gradient。 */
float square_gradient(vec2 uv) {
	float wedges_1 = wedges_mask_1(uv);
	float wedges_2 = wedges_mask_2(uv);
	float flipped_wedges_1 = wedges_mask_1(vec2(1.0 - uv.x, uv.y));
	float inverted_wedges_1 = 1.0 - wedges_1;
	float inverted_wedges_2 = 1.0 - wedges_2;
	float inverted_flipped_wedges_1 = 1.0 - flipped_wedges_1;

	float region_1 = min(
			mix(0.0, 0.25, uv.y),
			min(inverted_wedges_1, inverted_wedges_2)
	);
	float region_2 = min(
			mix(0.5, 0.25, uv.x),
			min(flipped_wedges_1, wedges_2)
	);
	float region_3 = min(
			mix(0.75, 0.5, uv.y),
			min(inverted_flipped_wedges_1, inverted_wedges_2)
	);
	float region_4 = min(
			mix(0.75, 1.0, uv.x),
			min(wedges_2, inverted_wedges_1)
	);

	return max(max(region_1, region_2), max(region_3, region_4));
}

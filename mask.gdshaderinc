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

struct alternate_mask_result
{
	float rows;
	float columns;
};

struct blind_mask_result
{
	float raw_mask;
	float one_sided;
	float symmetrical;
};

struct wedges_mask_result
{
	float subdivision_1;
	float subdivision_2;
	float subdivision_3;
};

/* Alternates 0 and 1 between cell rows and columns. num_steps sets how many
 * cells tile each axis.
 *
 * 沿 Y 方向逐行交替，沿 X 方向逐列交替。num_steps 决定两个轴的格子数量。 */
alternate_mask_result uv_alternate_mask(vec2 uv, uint num_steps) {
	vec2 cell = floor(uv * float(num_steps));

	alternate_mask_result result;
	result.rows = abs(mod(cell.y, 2.0));
	result.columns = abs(mod(cell.x, 2.0));

	return result;
}

alternate_mask_result uv_alternate_mask(vec2 uv) {
	return uv_alternate_mask(uv, uint(4));
}

/* Blind stripes expose their raw, one-sided, and symmetrical masks together.
 * rotation turns the stripe direction and tiling sets the stripe count.
 *
 * 百叶窗同时返回原始、单向和对称遮罩。
 * rotation 转动条纹方向，tiling 设定条纹数量。 */
blind_mask_result uv_blind_mask(
		vec2 uv,
		float rotation,
		float progress,
		float tiling,
		float feather) {
	vec2 offset = uv - vec2(0.5);
	float angle = rotation * TAU;
	float sine = sin(angle);
	float cosine = cos(angle);
	vec2 rotated_uv = vec2(
			offset.x * cosine - offset.y * sine,
			offset.x * sine + offset.y * cosine
	) + vec2(0.5);

	float raw_mask = rotated_uv.x * tiling;

	blind_mask_result result;
	result.raw_mask = raw_mask;
	result.one_sided = smoothstep(progress, progress + feather, fract(raw_mask));
	result.symmetrical = smoothstep(
			progress,
			progress + feather,
			ping_pong(raw_mask, 1.0, 1.0).result
	);

	return result;
}

blind_mask_result uv_blind_mask(vec2 uv) {
	return uv_blind_mask(uv, 0.0, 0.5, 2.0, 0.02);
}

/* Checkered mask alternating per cell. subdivisions counts rows and
 * columns before the doubling applied here, keeping the UE graph
 * behavior. Pairs well with grid patterns to alternate values per cell.
 * Matches Checker Mask.
 *
 * 逐格交替的棋盘格遮罩。subdivisions 为加倍前的行列数，此处保留 UE 图的加倍行为。
 * 适合与网格类图案搭配做逐格交替。对应 Checker Mask。 */
float uv_checkerboard_mask(vec2 uv, vec2 subdivisions) {
	vec2 cell = floor(uv * subdivisions * 2.0);
	return mod(cell.x + cell.y, 2.0);
}

float uv_checkerboard_mask(vec2 uv) {
	return uv_checkerboard_mask(uv, vec2(4.0));
}

/* Concentric sine rings sharpened through glow_min_max.
 * keep_inside_bounds clips everything beyond the container circle.
 *
 * 同心正弦环纹经 glow_min_max 锐化。
 * keep_inside_bounds 为 true 时裁剪容器圆以外的部分。 */
float uv_radial_glow_mask(
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

float uv_radial_glow_mask(vec2 uv) {
	return uv_radial_glow_mask(uv, 3.0, vec2(0.51, 0.49), false);
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
radial_segments_result uv_radial_segments_mask(
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

radial_segments_result uv_radial_segments_mask(vec2 uv) {
	return uv_radial_segments_mask(uv, 0.8, 0.002, 5.0);
}

/* Alternating concentric rings with an integer subdivision count.
 * glow_min_max sharpens ring falloff the same way SDF glow does.
 * keep_inside_bounds clips beyond the container circle. Matches Ring
 * Mask.
 *
 * 按整数细分数生成同心环纹。
 * glow_min_max 以 SDF 同款方式控制环的软硬，keep_inside_bounds 裁剪容器圆以外的部分。
 * 对应 Ring Mask。 */
float uv_ring_mask(vec2 uv, vec2 glow_minmax, int subdivisions, bool keep_inside_bounds) {
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
sectors_result uv_sectors_mask(
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

sectors_result uv_sectors_mask(vec2 uv) {
	return uv_sectors_mask(uv, 4.0, 0.8, 0.97, 0.05, 4.0, loop_0_1(0.2), false);
}

/* Diagonal wedge masks matching MF_UI_WedgesMask. The result contains two,
 * four, and eight triangle regions.
 *
 * 对角楔形遮罩，对应 MF_UI_WedgesMask。
 * 结果包含两个、四个和八个三角形区域。 */
wedges_mask_result uv_wedges_mask(vec2 uv) {
	float subdivision_1 = ceil(uv.y - uv.x);
	float diagonal_2 = ceil(uv.y - (1.0 - uv.x));
	float subdivision_2 = 1.0 - max(
			clamp(diagonal_2 - subdivision_1, 0.0, 1.0),
			clamp(subdivision_1 - diagonal_2, 0.0, 1.0)
	);
	float subdivision_3 = mix(
			1.0 - subdivision_2,
			subdivision_2,
			uv_checkerboard_mask(uv, vec2(1.0))
	);

	wedges_mask_result result;
	result.subdivision_1 = subdivision_1;
	result.subdivision_2 = subdivision_2;
	result.subdivision_3 = subdivision_3;

	return result;
}

/* Square-space angular gradient built from four diagonal wedges remapped
 * to quarter ranges and combined with max. Combine with an SDF box
 * outline to shade around a square frame. Matches Square Gradient.
 *
 * 方形空间的角度渐变：四块对角楔形各自重映射到四分之一区间后取最大值合并。
 * 与 SDF 方框描边组合可做方框周围的着色。对应 Square Gradient。 */
float square_gradient(vec2 uv) {
	wedges_mask_result wedges = uv_wedges_mask(uv);
	wedges_mask_result flipped_wedges = uv_wedges_mask(vec2(1.0 - uv.x, uv.y));
	float wedges_1 = wedges.subdivision_1;
	float wedges_2 = wedges.subdivision_2;
	float flipped_wedges_1 = flipped_wedges.subdivision_1;
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

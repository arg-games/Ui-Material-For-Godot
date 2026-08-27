#include "aspect_ratio.gdshaderinc"
#include "random.gdshaderinc"
#include "../transform.gdshaderinc"
#include "../mask.gdshaderinc"

struct pattern_result
{
	vec2 pattern_uvs;
	vec2 scaled_pattern_uvs;
	vec2 raw_uvs;
};

/* Tiles the coordinates into a grid. pattern_uvs repeats per cell,
 * raw_uvs keeps the untiled product, and scaled_pattern_uvs rescales
 * cells toward square so shapes stay consistent across tiling and
 * container aspect. Matches Grid Tiling.
 *
 * 把坐标平铺成网格。pattern_uvs 逐格重复，raw_uvs 保留未取模的平铺结果，
 * scaled_pattern_uvs 将单元格校准为正方形，图案在不同平铺数与容器比例下保持一致。
 * 宽高比从连续 UV 的 fwidth 取得。对应 Grid Tiling。 */
pattern_result pattern(vec2 uv, vec2 tiling) {
	pattern_result result;

	result.raw_uvs = uv * tiling;
	result.pattern_uvs = fract(result.raw_uvs);

	vec2 tiling_aspect = clamp(
			vec2(tiling.x / tiling.y, tiling.y / tiling.x),
			vec2(0.0),
			vec2(1.0)
	);
	vec2 scale = tiling_aspect / get_aspect_ratio(uv).ratio;
	result.scaled_pattern_uvs = scale_uv(result.pattern_uvs, vec2(0.5), scale);

	return result;
}
pattern_result pattern(vec2 uv) {
	return pattern(uv, vec2(2.0));
}

struct halftone_result
{
	float fill;
	float size_mask;
	vec2 pattern_uvs;
};

/* Dot-grid halftone sized by an input grayscale gradient. Aspect
 * scaling keeps dots round, then pan, rotate, and tile by density.
 * fill is the dot mask, size_mask the interpolated dot diameter, and
 * pattern_uvs the tiled coordinates for drawing custom shapes instead
 * of dots. Matches MF_UI_Halftone. Stroke pins stay unconnected, so the
 * dot circle uses stroke 0.1 relative to size.
 *
 * 半调网点，点径由灰度输入控制。先按 UV 的 fwidth 缩放保证圆点是正圆，
 * 再做平移、旋转并按 density 平铺。
 * fill 为点阵遮罩，size_mask 为插值后的点径，pattern_uvs 为可替换形状的平铺坐标。
 * 对应 MF_UI_Halftone。描边引脚未连接，内部圆点使用随尺寸的 0.1 描边。 */
halftone_result halftone(
		vec2 uv,
		float input_gradient,
		float density,
		float min_size,
		float max_size,
		float glow_min,
		float glow_max,
		vec2 pan_speed,
		float rotation,
		float time) {
	vec2 center = vec2(0.5);
	vec2 aspect_scale = 1.0 / get_aspect_ratio(uv).ratio;
	vec2 scaled_uv = scale_uv(uv, center, aspect_scale);
	vec2 panned_uv = scaled_uv + time * pan_speed;

	float angle = rotation * TAU;
	float sine = sin(angle);
	float cosine = cos(angle);
	vec2 offset = panned_uv - center;
	vec2 rotated_uv = vec2(
			offset.x * cosine - offset.y * sine,
			offset.x * sine + offset.y * cosine
	) + center;

	halftone_result result;
	result.pattern_uvs = fract(rotated_uv * density);
	result.size_mask = mix(min_size, max_size, input_gradient);
	result.fill = sdf_circle(
			result.pattern_uvs,
			result.size_mask,
			glow_min,
			glow_max,
			0.1,
			true
	).fill;

	return result;
}

halftone_result halftone(vec2 uv) {
	float input_gradient = sdf_circle(uv, 0.5, 0.0, 1.0, 0.1, true).fill;

	return halftone(
			uv,
			input_gradient,
			50.0,
			-0.2,
			1.0,
			0.0,
			0.2,
			vec2(-0.01, 0.01),
			0.0,
			TIME
	);
}

struct hexagon_tiling_result
{
	float fill;
	float outline;
	float outline_border;
	vec2 pattern_uvs;
};

/* Hexagonal lattice matching MF_UI_HexagonTiling. fill covers the
 * hexagons, outline the gaps between them, outline_border strokes the
 * gap edges by hex_thickness, and pattern_uvs centers on each cell.
 * square_rectangle = (sqrt(3), 1) supplies the 30-60-90 lattice offsets
 * and the 60-degree SDF edges. Glow is the graph constant 0.03.
 *
 * 六边形网格，对应 MF_UI_HexagonTiling。
 * fill 为六边形本体，outline 为六边形之间的空隙，
 * outline_border 按 hex_thickness 给空隙描边，pattern_uvs 以各单元格为中心。
 * square_rectangle = (sqrt(3), 1) 提供 30-60-90 网格偏移与 60 度边。
 * 柔边宽度沿用 UE 图常量 0.03。 */
hexagon_tiling_result hexagon_tiling(
		vec2 uv,
		float tiling,
		float hex_thickness,
		float hex_distance) {
	const float GLOW = 0.03;
	vec2 square_rectangle = vec2(sqrt(3.0), 1.0);
	vec2 uvs = uv * tiling + square_rectangle;

	vec2 hex_center_even = floor(uvs / square_rectangle) + vec2(0.5);
	vec2 hex_center_odd = floor((uvs - vec2(1.0, 0.5)) / square_rectangle) + vec2(1.0);

	vec2 even = uvs - hex_center_even * square_rectangle;
	vec2 odd = uvs - hex_center_odd * square_rectangle;
	vec2 pattern_uvs = (dot(even, even) < dot(odd, odd)) ? even : odd;

	vec2 abs_uv = abs(pattern_uvs);
	float hexagon_sdf = max(dot(abs_uv, square_rectangle * 0.5), abs_uv.y);

	hexagon_tiling_result result;
	result.outline = smoothstep(hex_distance, hex_distance + GLOW, hexagon_sdf);
	result.fill = 1.0 - result.outline;
	float inner = smoothstep(
			hex_distance + hex_thickness,
			hex_distance + hex_thickness + GLOW,
			hexagon_sdf
	);
	result.outline_border = clamp(result.outline - inner, 0.0, 1.0);
	result.pattern_uvs = pattern_uvs + vec2(0.5);

	return result;
}

hexagon_tiling_result hexagon_tiling(vec2 uv) {
	return hexagon_tiling(uv, 4.0, 0.01, 0.46);
}

struct truchet_result
{
	float mask;
	vec2 pattern_uvs;
	float sdf;
};

/* Truchet tiles matching MF_UI_Truchet. Grid cells flip randomly by
 * seed, then reflect across sign(x+y), so each tile becomes a quarter
 * arc or a diagonal line. mask draws lines or filled regions,
 * pattern_uvs flows along the pattern, and sdf exposes the raw signed
 * distance for blending.
 *
 * Truchet 图案，对应 MF_UI_Truchet。
 * 网格单元格按 seed 随机翻转，再沿 sign(x+y) 镜像，每格成为四分之一圆弧或对角线。
 * mask 绘制线条或填充区域，pattern_uvs 沿图案流动，
 * sdf 提供原始距离场供混合使用。
 * 未连接的 UE 引脚：tiling=2、line_thickness=0.1、feather=0.1、
 * draw_regions=false、use_line=false、flow_speed=0.1、flow_tiling=7、seed=1.6。
 * 区域反相与流向符号分别来自两次 MF_UI_CheckerMask 调用，此处用 checkerboard_mask 复现。
 * 线性时间引脚未连接，流动动画用 loop_0_1(time, flow_speed)。
 * 描边 SmoothStep 的 min/max 为 feather 与 -feather，写成 1-smoothstep 以保证 GLSL 合法。 */
truchet_result truchet(
		vec2 uv,
		vec2 tiling,
		float line_thickness,
		float feather,
		bool draw_regions,
		bool use_line,
		float flow_speed,
		float flow_tiling,
		float seed,
		float time) {
	pattern_result grid = pattern(uv, tiling);
	vec2 centered = grid.pattern_uvs - vec2(0.5);
	float random_mask = round(random(floor(grid.raw_uvs), seed).d1);
	vec2 flipped = vec2(centered.x, (random_mask * 2.0 - 1.0) * centered.y);
	vec2 rotated_cells = flipped * sign(flipped.x + flipped.y + 0.001) - vec2(0.5);

	float shape = use_line
			? abs(rotated_cells.x + rotated_cells.y)
			: length(rotated_cells);
	float sdf = shape - 0.5;

	float outline_mask = 1.0 - smoothstep(
			-feather,
			feather,
			abs(sdf) - line_thickness
	);

	float checker = checkerboard_mask(uv, tiling);
	float should_invert = ((random_mask >= 1.0) == (checker >= 1.0)) ? 1.0 : 0.0;
	float region_mask = smoothstep(0.0, feather, mix(sdf, -sdf, should_invert));

	float flow_checker_sign = checkerboard_mask(uv, vec2(tiling.x)) * 2.0 - 1.0;
	float flow_u = (
			atan(rotated_cells.x, rotated_cells.y) * flow_checker_sign / PI
			- loop_0_1(time, flow_speed)
	) * flow_tiling;
	float flow_v = abs((sdf + line_thickness) / (line_thickness * 2.0) - 0.5);

	truchet_result result;
	result.mask = draw_regions ? region_mask : outline_mask;
	result.pattern_uvs = fract(vec2(flow_u, flow_v));
	result.sdf = sdf;

	return result;
}

truchet_result truchet(vec2 uv) {
	return truchet(
			uv,
			vec2(2.0),
			0.1,
			0.1,
			false,
			false,
			0.1,
			7.0,
			1.6,
			TIME
	);
}

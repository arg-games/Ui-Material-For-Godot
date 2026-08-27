#include "../utilities/aspect_ratio.gdshaderinc"
#include "../utilities/weighted_corners.gdshaderinc"
#include "sdf_shape.gdshaderinc"

/* Rounded box signed distance field matching MF_UI_SDF_Box. Returns
 * sdf_shape_result: fill is the sharpened shape, outline is the inward
 * stroke, sdf and sdf_outline are the raw signed distances.
 * size is the half extent relative to the input coordinates, 0.5 fills
 * the container. corner_radiuses holds per-corner values, x, y, z, w map
 * to top-left, bottom-left, top-right, bottom-right, 0 stays square and
 * 1 rounds fully. glow_min and glow_max sharpen the falloff.
 * stroke_thickness draws inward from the edge and scales with size when
 * is_stroke_thickness_relative_to_size is true, picking the width or the
 * height through dimension_to_pick_for_stroke. When keep_aspect_ratio is
 * true, the continuous input UV uses fwidth so stretched containers keep
 * even corners and strokes. Formula from Inigo Quilez's
 * 2D distance functions.
 *
 * 圆角矩形有向距离场，对应 MF_UI_SDF_Box。返回 sdf_shape_result：
 * fill 是锐化后的形状，outline 是内描边，sdf 与 sdf_outline 是原始距离场。
 * size 为相对输入坐标的半尺寸，0.5 恰好铺满容器。corner_radiuses 为四角数值，
 * x、y、z、w 分别对应左上、左下、右上、右下，0 为直角，1 为最大圆角。
 * glow_min 与 glow_max 控制边缘软硬。描边自边缘向内绘制，
 * is_stroke_thickness_relative_to_size 为 true 时随尺寸缩放，
 * dimension_to_pick_for_stroke 为 0 取宽度，为 1 取高度。
 * keep_aspect_ratio 为 true 时根据连续 UV 的 fwidth 自动校正，
 * 容器被拉伸后圆角与描边仍保持均匀。
 *
 * 公式来自 Inigo Quilez 的 2D 距离函数。 */
sdf_shape_result sdf_box(
		vec2 uv,
		vec2 size,
		float glow_min,
		float glow_max,
		vec4 corner_radiuses,
		float stroke_thickness,
		bool is_stroke_thickness_relative_to_size,
		float dimension_to_pick_for_stroke,
		bool keep_aspect_ratio) {

	vec2 ratio = keep_aspect_ratio ? get_aspect_ratio(uv).ratio : vec2(1.0);

	// Remap coord space from 0 1 to -1 1, then correct its aspect.
	vec2 centered_uv = abs((uv - vec2(0.5)) * 2.0) * ratio;

	float picked_dimension = mix(size.x, size.y, dimension_to_pick_for_stroke);
	float stroke = is_stroke_thickness_relative_to_size
			? picked_dimension * stroke_thickness
			: stroke_thickness;

	float corner_radius = weighted_corners(uv, corner_radiuses);

	vec2 q = centered_uv - size + corner_radius;

    float sdf = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
    float sdf_outline = abs(sdf) - stroke;
    float outline_sdf = max(sdf_outline, sdf);

    sdf_shape_result result;
	result.sdf = sdf;
	result.sdf_outline = sdf_outline;
	result.fill = 1.0 - smoothstep(glow_min, glow_max, sdf);
	result.outline = 1.0 - smoothstep(glow_min, glow_max, outline_sdf);

	return result;
}

/* Defaults follow the UE graph's unconnected pins. Aspect correction uses
 * the continuous input UV and therefore needs fragment-stage derivatives.
 *
 * 默认值取自 UE 图中未连接的引脚。宽高比校正从连续输入 UV 取得。 */
sdf_shape_result sdf_box(vec2 uv) {
	return sdf_box(uv, vec2(0.5), 0.0, 0.01, vec4(0.0), 0.1, true, 0.0, true);
}

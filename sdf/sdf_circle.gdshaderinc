#include "sdf_shape.gdshaderinc"

/* Circle signed distance field matching MF_UI_SDF_Circle. Returns
 * sdf_shape_result: fill is the sharpened shape, outline is the inward
 * stroke, sdf and sdf_outline are the raw signed distances.
 * size is the diameter relative to the input coordinates. glow_min and
 * glow_max sharpen the falloff. stroke_thickness draws inward from the
 * edge and scales with size when is_stroke_thickness_relative_to_size
 * is true.
 *
 * 圆形有向距离场，对应 MF_UI_SDF_Circle。返回 sdf_shape_result：
 * fill 是锐化后的形状，outline 是内描边，sdf 与 sdf_outline 是原始距离场。
 * size 为相对输入坐标的直径，glow_min 与 glow_max 控制边缘软硬。
 * 描边自边缘向内绘制，is_stroke_thickness_relative_to_size 为 true 时随尺寸缩放。 */
sdf_shape_result sdf_circle(
		vec2 uv,
		float size,
		float glow_min,
		float glow_max,
		float stroke_thickness,
		bool is_stroke_thickness_relative_to_size) {
	sdf_shape_result result;

	vec2 centered_uv = (uv - vec2(0.5)) * 2.0;
	result.sdf = length(centered_uv) - size;

	float stroke = is_stroke_thickness_relative_to_size
			? size * stroke_thickness
			: stroke_thickness;

	result.sdf_outline = abs(result.sdf) - stroke;

	result.fill = 1.0 - smoothstep(glow_min, glow_max, result.sdf);

	float outline_sdf = max(result.sdf_outline, result.sdf);
	result.outline = 1.0 - smoothstep(glow_min, glow_max, outline_sdf);

	return result;
}

/* Defaults follow the UE graph's unconnected pins.
 *
 * 默认值取自 UE 图中未连接的引脚。 */
sdf_shape_result sdf_circle(vec2 uv) {
	return sdf_circle(uv, 0.5, 0.0, 0.0, 0.1, true);
}

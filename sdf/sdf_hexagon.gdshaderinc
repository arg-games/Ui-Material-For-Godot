#include "sdf_shape.gdshaderinc"

/* Hexagon signed distance field matching MF_UI_SDF_Hexagon. Returns
 * sdf_shape_result: fill is the sharpened shape, outline is the inward
 * stroke, sdf and sdf_outline are the raw signed distances.
 * radius is the circumradius in centered coordinates spanning -1 to 1.
 * corner_roundness rounds the corners from 0 to 1, where 1 reaches the
 * hexagon inradius and the shape becomes fully round. glow_min and
 * glow_max sharpen the falloff. stroke_thickness draws inward from the
 * edge and scales with radius when is_stroke_thickness_relative_to_size
 * is true. Hexagon formula from Inigo Quilez's 2D distance functions.
 *
 * 六边形有向距离场，对应 MF_UI_SDF_Hexagon。返回 sdf_shape_result：
 * fill 是锐化后的形状，outline 是内描边，sdf 与 sdf_outline 是原始距离场。
 * radius 为居中坐标下的外接圆半径。corner_roundness 从 0 到 1 圆化边角，
 * 取 1 时到达内切圆半径，形状变为圆形。glow_min 与 glow_max 控制边缘软硬。
 * 描边自边缘向内绘制，is_stroke_thickness_relative_to_size 为 true 时随半径缩放。
 * 公式来自 Inigo Quilez 的二维距离函数文章。 */
sdf_shape_result sdf_hexagon(
		vec2 uv,
		float radius,
		float glow_min,
		float glow_max,
		float stroke_thickness,
		bool is_stroke_thickness_relative_to_size,
		float corner_roundness) {
	sdf_shape_result result;

	float corner_radius = radius * 0.8660254 * corner_roundness;
	float base_radius = radius - corner_radius;

	vec3 k = vec3(-0.8660254, 0.5, 0.57735027);
	vec2 p = abs((uv - vec2(0.5)) * 2.0);
	p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
	p -= vec2(clamp(p.x, -k.z * base_radius, k.z * base_radius), base_radius);
	result.sdf = length(p) * sign(p.y) - corner_radius;

	float stroke = is_stroke_thickness_relative_to_size
			? radius * stroke_thickness
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
sdf_shape_result sdf_hexagon(vec2 uv) {
	return sdf_hexagon(uv, 0.5, 0.0, 0.0, 0.1, true, 0.0);
}

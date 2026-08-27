#include "sdf_shape.gdshaderinc"

/* Equilateral triangle signed distance field matching MF_UI_SDF_Triangle.
 * Returns sdf_shape_result: fill is the sharpened shape, outline is the
 * inward stroke, sdf and sdf_outline are the raw signed distances.
 * The shape points up with its base parallel to the container
 * bottom. radius scales relative to the container; 1 makes the triangle
 * base span the whole container width. corner_roundness rounds the three
 * corners, larger values round more until the shape degenerates.
 * glow_min and glow_max sharpen the falloff. stroke_thickness draws
 * inward from the edge and scales with radius when
 * is_stroke_thickness_relative_to_size is true. Formula from Inigo
 * Quilez's 2D distance functions.
 *
 * 等边三角形有向距离场，对应 MF_UI_SDF_Triangle。返回 sdf_shape_result：
 * fill 是锐化后的形状，outline 是内描边，sdf 与 sdf_outline 是原始距离场。
 * 三角形尖角朝上，底边与容器底部平行。radius 相对容器缩放，
 * 取 1 时底边铺满容器宽度。corner_roundness 圆化三个角，数值越大越圆，
 * 过大时形状退化。glow_min 与 glow_max 控制边缘软硬。描边自边缘向内绘制，
 * is_stroke_thickness_relative_to_size 为 true 时随半径缩放。
 * 公式来自 Inigo Quilez 的二维距离函数文章。 */
sdf_shape_result sdf_triangle(
		vec2 uv,
		float radius,
		float glow_min,
		float glow_max,
		float stroke_thickness,
		bool is_stroke_thickness_relative_to_size,
		float corner_roundness) {
	sdf_shape_result result;

	const float sqrt3 = 1.7320508;

	vec2 centered_uv = (uv - vec2(0.5)) * 2.0;

	float stroke = is_stroke_thickness_relative_to_size
			? radius * stroke_thickness
			: stroke_thickness;
	stroke /= sqrt3;

	float size_with_roundness = radius - corner_roundness;
	float corner_radius = corner_roundness / sqrt3;

	vec2 p;
	p.x = abs(centered_uv.x) - size_with_roundness;
	p.y = -centered_uv.y + radius * (0.7 - sqrt3 * 0.25);
	p.y += size_with_roundness / sqrt3;
	if (p.x + sqrt3 * p.y > 0.0) {
		p = vec2(p.x - sqrt3 * p.y, -sqrt3 * p.x - p.y) * 0.5;
	}
	p.x -= clamp(p.x, -2.0 * size_with_roundness, 0.0);
	result.sdf = -length(p) * sign(p.y) - corner_radius;

	result.sdf_outline = abs(result.sdf) - stroke;

	result.fill = 1.0 - smoothstep(glow_min, glow_max, result.sdf);

	float outline_sdf = max(result.sdf_outline, result.sdf);
	result.outline = 1.0 - smoothstep(glow_min, glow_max, outline_sdf);

	return result;
}

/* Defaults follow the UE graph's unconnected pins.
 *
 * 默认值取自 UE 图中未连接的引脚。 */
sdf_shape_result sdf_triangle(vec2 uv) {
	return sdf_triangle(uv, 0.5, 0.0, 0.0, 0.1, true, 0.0);
}

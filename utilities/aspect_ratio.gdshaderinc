// Aspect ratio helpers converted from the UE material functions.

struct aspect_ratio_result
{
	vec2 ratio;
	vec2 horizontal;
	vec2 vertical;
};

/* Computes the container ratio from the screen-space rate of change of
 * a continuous UV. Call this from fragment code before fract, floor, or
 * another discontinuous coordinate operation. fwidth(UV) is the inverse
 * of the number of pixels covered by one UV unit, so swapping its axes
 * gives the ratio needed to keep procedural shapes square.
 *
 * 根据连续 UV 的屏幕空间变化率计算容器比例。
 * 必须在 fract、floor 等不连续坐标操作前从片元代码调用。
 * fwidth(UV) 表示每个像素覆盖的 UV 变化量，交换两个分量后可得到
 * 让程序形状保持正方形所需的比例。对应 Godot 的 Aspect Ratio。 */
aspect_ratio_result get_aspect_ratio(vec2 uv) {
	vec2 uv_rate = max(fwidth(uv), vec2(0.000001));

	aspect_ratio_result result;
	result.horizontal = vec2(uv_rate.y / uv_rate.x, 1.0);
	result.vertical = vec2(1.0, uv_rate.x / uv_rate.y);
	result.ratio = max(result.horizontal, result.vertical);

	return result;
}

/* Centers the UV before applying the derivative-based ratio. The result
 * can extend outside 0..1 on the longer axis. This is expected because
 * the unused area keeps the shape centered while preserving its ratio.
 *
 * 先把 UV 移到中心，再应用基于导数的比例。
 * 长轴结果可能超出 0 到 1，这是保持形状居中的正常结果。 */
vec2 aspect_correct_uv(vec2 uv) {
	vec2 ratio = get_aspect_ratio(uv).ratio;

	return (uv - vec2(0.5)) * ratio + vec2(0.5);
}

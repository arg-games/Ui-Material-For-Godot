/* Picks a weight from corners based on the quadrant uv falls in.
 * corners.x, y, z, w map to top-left, bottom-left, top-right,
 * bottom-right.
 *
 * 按 uv 所在象限从四角权重中取值。
 * corners 的 x、y、z、w 分别对应左上、左下、右上、右下。 */
float weighted_corners(vec2 uv, vec4 corners) {
	// 对应 UE 中先做 ConstantBiasScale(Bias=-0.5, Scale=2.0)，再取 Ceil，最后 Saturate。
	vec2 split = clamp(ceil((uv - vec2(0.5)) * 2.0), 0.0, 1.0);

	// x 不超过 0.5 时取左侧的 xy，否则取右侧的 zw
	vec2 side = mix(corners.xy, corners.zw, split.x);

	// y 不超过 0.5 时取 side.x，否则取 side.y
	return mix(side.x, side.y, split.y);
}

float weighted_corners(vec2 uv) {
	return weighted_corners(uv, vec4(0.2, 0.1, 0.3, 0.5));
}

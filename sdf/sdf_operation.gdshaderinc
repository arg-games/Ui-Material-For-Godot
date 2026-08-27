/* SDF boolean operations matching the UE UI Material Lab functions
 * MF_UI_SDF_Union, MF_UI_SDF_Subtraction and MF_UI_SDF_Intersection.
 * All three share sdf_operation_result: exact keeps hard edges and
 * smoothed blends both fields across blend_amount, described as a 0-1
 * value controlling how much the shapes merge; only the smoothed output
 * uses it. Formulas from Inigo Quilez's SDF boolean operations.
 *
 * 有向距离场布尔运算，对应 UE UI Material Lab 的 MF_UI_SDF_Union、
 * MF_UI_SDF_Subtraction 与 MF_UI_SDF_Intersection。
 * 三个函数共用 sdf_operation_result：exact 保持硬边，
 * smoothed 在 blend_amount 范围内混合两个场。
 * 该参数取 0-1 值，控制形状融合程度，只影响 smoothed 输出。
 * 公式来自 Inigo Quilez 的 SDF 布尔运算文章。 */
struct sdf_operation_result
{
	float exact;
	float smoothed;
};

/* Boolean union. exact is min(a, b) and keeps hard edges.
 *
 * 并集布尔运算。exact 取 min(a, b)，保持硬边。 */
sdf_operation_result sdf_union(
		float a,
		float b,
		float blend_amount) {
	sdf_operation_result result;

	result.exact = min(a, b);

	float h = clamp(0.5 + 0.5 * (b - a) / blend_amount, 0.0, 1.0);
	result.smoothed = mix(b, a, h) - blend_amount * h * (1.0 - h);

	return result;
}

/* Boolean subtraction. exact is max(a, -b) and keeps hard edges.
 * Changing the order of the inputs changes the outcome.
 *
 * 差集布尔运算。exact 取 max(a, -b)，保持硬边。
 * 调换输入顺序会改变结果。 */
sdf_operation_result sdf_subtraction(
		float a,
		float b,
		float blend_amount) {
	sdf_operation_result result;

	result.exact = max(a, -b);

	float h = clamp(0.5 - 0.5 * (a + b) / blend_amount, 0.0, 1.0);
	result.smoothed = mix(a, -b, h) + blend_amount * h * (1.0 - h);

	return result;
}

/* Boolean intersection. exact is max(a, b) and keeps hard edges.
 *
 * 交集布尔运算。exact 取 max(a, b)，保持硬边。 */
sdf_operation_result sdf_intersection(
		float a,
		float b,
		float blend_amount) {
	sdf_operation_result result;

	result.exact = max(a, b);

	float h = clamp(0.5 - 0.5 * (b - a) / blend_amount, 0.0, 1.0);
	result.smoothed = mix(b, a, h) + blend_amount * h * (1.0 - h);

	return result;
}

/* Defaults follow the UE graph's unconnected pins.
 *
 * 默认值取自 UE 图中未连接的引脚。 */
sdf_operation_result sdf_union(float a, float b) {
	return sdf_union(a, b, 0.2);
}

sdf_operation_result sdf_subtraction(float a, float b) {
	return sdf_subtraction(a, b, 0.2);
}

sdf_operation_result sdf_intersection(float a, float b) {
	return sdf_intersection(a, b, 0.2);
}

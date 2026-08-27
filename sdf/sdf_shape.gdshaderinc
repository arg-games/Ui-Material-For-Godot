/* Shared result struct for every SDF shape function. Fields mirror the
 * four UE outputs: fill is the sharpened shape, outline is the inward
 * stroke, sdf and sdf_outline are the raw signed distances.
 *
 * 所有 SDF 形状函数共用的结果结构体。
 * fill 是锐化后的形状，outline 是内描边，sdf 与 sdf_outline 是原始距离场。 */
struct sdf_shape_result
{
	float fill;
	float outline;
	float sdf;
	float sdf_outline;
};

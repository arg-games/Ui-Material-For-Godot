// 两种分段输出的曲线差异见
// https://www.desmos.com/calculator/b0vqnsuvh0

struct stepped_gradient_result
{
	float range;
	float difference;
};

/* Turns a gradient into discrete steps like Posterize. range keeps the
 * initial range so the last step reaches the original maximum;
 * difference spaces steps at 1/num_steps. Matches Stepped Gradient.
 *
 * 把渐变切成离散阶梯，类似海报化。
 * range 保持原始范围，最后一级到达原最大值；difference 的阶梯间隔为 1/num_steps。
 * 对应 Stepped Gradient。 */
stepped_gradient_result stepped_gradient(float gradient, uint num_steps) {
	float step_count = float(num_steps);
	float t = floor(gradient * step_count);

	stepped_gradient_result result;
	result.range = t / max(step_count - 1.0, 0.01);
	result.difference = t / step_count;

	return result;
}

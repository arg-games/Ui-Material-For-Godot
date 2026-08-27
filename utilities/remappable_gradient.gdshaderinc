// 渐变优先用 GradientTexture1D 采样，少用这里的数学硬算。
// 纹理采样性能更高，美术能在 Inspector 里直接拖拽编辑。
//
// 用法：
// 1. 主 shader 顶部声明 uniform sampler2D my_gradient : source_color;
// 2. fragment() 中读取，遮罩通常取 UV.x：
//    vec3 color = texture(my_gradient, vec2(mask, 0.0)).rgb;
// 3. 材质 Inspector 中为 my_gradient 新建 GradientTexture1D。

/* Linear weight of mask between pos_a and pos_b.
 *
 * 计算 mask 在 pos_a 到 pos_b 区间内的线性权重。
 * 对应 UE 中的 Subtract、Divide 与 Saturate 节点。 */
float _get_grad_alpha(float pos_a, float pos_b, float mask) {
	return clamp((mask - pos_a) / (pos_b - pos_a), 0.0, 1.0);
}

/* Maps up to three colors onto a grayscale input like a gradient map,
 * stop positions controlled by p1..p3. Any gradient or grayscale
 * texture works as mask. Matches the Gradient 3 Colors output of
 * Remappable Gradient - color.
 *
 * 类似渐变映射，把最多三个颜色映射到灰度输入上，停靠点位置由 p1 到 p3 控制。
 * mask 可用任意渐变或灰度纹理。
 * 对应 Remappable Gradient - color 的 Gradient 3 Colors 输出。 */
vec3 gradient_3(
		float mask,
		vec3 c1,
		vec3 c2,
		vec3 c3,
		float p1,
		float p2,
		float p3) {
	vec3 color = mix(c1, c2, _get_grad_alpha(p1, p2, mask));
	color = mix(color, c3, _get_grad_alpha(p2, p3, mask));
	return color;
}

/* Default positions 0.0, 0.25, 0.45.
 *
 * 位置缺省为 0.0、0.25、0.45。 */
vec3 gradient_3(float mask, vec3 c1, vec3 c2, vec3 c3) {
	return gradient_3(mask, c1, c2, c3, 0.0, 0.25, 0.45);
}

/* Preset colors red, green, purple.
 *
 * 预设红、绿、紫三色。 */
vec3 gradient_3(float mask) {
	vec3 c1 = vec3(1.0, 0.036, 0.036);
	vec3 c2 = vec3(0.181, 0.776, 0.145);
	vec3 c3 = vec3(0.736, 0.115, 0.921);

	return gradient_3(mask, c1, c2, c3);
}

/* Four-color variant of gradient_3.
 *
 * gradient_3 的四色变体。对应 Remappable Gradient - color 的 Gradient 4 Colors 输出。 */
vec3 gradient_4(
		float mask,
		vec3 c1,
		vec3 c2,
		vec3 c3,
		vec3 c4,
		float p1,
		float p2,
		float p3,
		float p4) {
	vec3 color = gradient_3(mask, c1, c2, c3, p1, p2, p3);
	return mix(color, c4, _get_grad_alpha(p3, p4, mask));
}

/* Default positions 0.0, 0.25, 0.45, 0.65.
 *
 * 位置缺省为 0.0、0.25、0.45、0.65。 */
vec3 gradient_4(float mask, vec3 c1, vec3 c2, vec3 c3, vec3 c4) {
	return gradient_4(mask, c1, c2, c3, c4, 0.0, 0.25, 0.45, 0.65);
}

/* Preset colors red, green, purple, yellow.
 *
 * 预设红、绿、紫、黄四色。 */
vec3 gradient_4(float mask) {
	vec3 c1 = vec3(1.0, 0.036, 0.036);
	vec3 c2 = vec3(0.181, 0.776, 0.145);
	vec3 c3 = vec3(0.736, 0.115, 0.921);
	vec3 c4 = vec3(0.932, 0.658, 0.082);

	return gradient_4(mask, c1, c2, c3, c4);
}

/* Five-color variant of gradient_3.
 *
 * gradient_3 的五色变体。对应 Remappable Gradient - color 的 Gradient 5 Colors 输出。 */
vec3 gradient_5(
		float mask,
		vec3 c1,
		vec3 c2,
		vec3 c3,
		vec3 c4,
		vec3 c5,
		float p1,
		float p2,
		float p3,
		float p4,
		float p5) {
	vec3 color = gradient_4(mask, c1, c2, c3, c4, p1, p2, p3, p4);
	return mix(color, c5, _get_grad_alpha(p4, p5, mask));
}

/* Default positions 0.0, 0.25, 0.45, 0.65, 1.0.
 *
 * 位置缺省为 0.0、0.25、0.45、0.65、1.0。 */
vec3 gradient_5(float mask, vec3 c1, vec3 c2, vec3 c3, vec3 c4, vec3 c5) {
	return gradient_5(mask, c1, c2, c3, c4, c5, 0.0, 0.25, 0.45, 0.65, 1.0);
}

/* Preset colors red, green, purple, yellow, blue.
 *
 * 预设红、绿、紫、黄、蓝五色。 */
vec3 gradient_5(float mask) {
	vec3 c1 = vec3(1.0, 0.036, 0.036);
	vec3 c2 = vec3(0.181, 0.776, 0.145);
	vec3 c3 = vec3(0.736, 0.115, 0.921);
	vec3 c4 = vec3(0.932, 0.658, 0.082);
	vec3 c5 = vec3(0.054, 0.129, 0.953);

	return gradient_5(mask, c1, c2, c3, c4, c5);
}

/* Grayscale version of gradient_3, matching Remappable Gradient -
 * float. Feeding Linear Time lets a drawn gradient drive animation
 * timing without curves.
 *
 * gradient_3 的灰度版本，把三个数值映射到灰度输入上。
 * 对应 Remappable Gradient - float。
 * 以 Linear Time 作输入，自定渐变即可驱动动画节奏，无需曲线资源。 */
float gradient_3_float(
		float mask,
		float v1,
		float v2,
		float v3,
		float p1,
		float p2,
		float p3) {
	return gradient_3(mask, vec3(v1), vec3(v2), vec3(v3), p1, p2, p3).r;
}

/* Default positions match gradient_3.
 *
 * 位置缺省与 gradient_3 相同。 */
float gradient_3_float(float mask, float v1, float v2, float v3) {
	return gradient_3(mask, vec3(v1), vec3(v2), vec3(v3)).r;
}

/* Preset values 1.0, 0.0, 0.2.
 *
 * 预设数值 1.0、0.0、0.2。 */
float gradient_3_float(float mask) {
	float v1 = 1.0;
	float v2 = 0.0;
	float v3 = 0.2;

	return gradient_3_float(mask, v1, v2, v3);
}

/* Four-value variant of gradient_3_float.
 *
 * gradient_3_float 的四点变体。 */
float gradient_4_float(
		float mask,
		float v1,
		float v2,
		float v3,
		float v4,
		float p1,
		float p2,
		float p3,
		float p4) {
	return gradient_4(mask, vec3(v1), vec3(v2), vec3(v3), vec3(v4), p1, p2, p3, p4).r;
}

/* Default positions match gradient_4.
 *
 * 位置缺省与 gradient_4 相同。 */
float gradient_4_float(float mask, float v1, float v2, float v3, float v4) {
	return gradient_4(mask, vec3(v1), vec3(v2), vec3(v3), vec3(v4)).r;
}

/* Preset values 0.0, 1.0, 0.2, 0.8.
 *
 * 预设数值 0.0、1.0、0.2、0.8。 */
float gradient_4_float(float mask) {
	float v1 = 0.0;
	float v2 = 1.0;
	float v3 = 0.2;
	float v4 = 0.8;

	return gradient_4_float(mask, v1, v2, v3, v4);
}

/* Five-value variant of gradient_3_float.
 *
 * gradient_3_float 的五点变体。 */
float gradient_5_float(
		float mask,
		float v1,
		float v2,
		float v3,
		float v4,
		float v5,
		float p1,
		float p2,
		float p3,
		float p4,
		float p5) {
	return gradient_5(mask, vec3(v1), vec3(v2), vec3(v3),
			vec3(v4), vec3(v5), p1, p2, p3, p4, p5).r;
}

/* Default positions match gradient_5.
 *
 * 位置缺省与 gradient_5 相同。 */
float gradient_5_float(float mask, float v1, float v2, float v3, float v4, float v5) {
	return gradient_5(mask, vec3(v1), vec3(v2), vec3(v3), vec3(v4), vec3(v5)).r;
}

/* Preset values 0.0, 1.0, 0.2, 0.8, 0.1.
 *
 * 预设数值 0.0、1.0、0.2、0.8、0.1。 */
float gradient_5_float(float mask) {
	float v1 = 0.0;
	float v2 = 1.0;
	float v3 = 0.2;
	float v4 = 0.8;
	float v5 = 0.1;

	return gradient_5_float(mask, v1, v2, v3, v4, v5);
}

// Random functions converted from the UE material function.

/* Pseudo-random value from a single float, matching the Single Value
 * output of Random. Same input always yields the same output.
 *
 * 由单个浮点数生成伪随机值，相同输入必得相同输出。
 * 对应 Random 的 Single Value 输出。 */
float single_value(float value) {
	return fract(sin(value * TAU)) * 2.0 - 1.0;
}

struct random_result
{
	float d1;
	vec2 d2;
};

/* Grayscale and 2D pseudo-random noise from a vector2 input, matching
 * the 1D and 2D outputs of Random. seed differentiates noises that
 * would otherwise look alike.
 *
 * 由 vec2 输入生成灰度与二维伪随机噪声，对应 Random 的 1D 与 2D 输出。
 * seed 用于区分外观相同的噪声。
 * UE 节点链先做常数向量点乘，再取正弦并乘以种子，
 * 然后用 fract 取小数，重映射到 -1 到 1 后取绝对值。
 * UE 的 Sine 默认 Period 为 1，等价于 sin(x * TAU)。 */
random_result random(vec2 value, float seed) {
	float combined_seed = seed + 43758.546875;

	vec2 const_x = vec2(351.635010, 649.856018);
	vec2 const_y = vec2(574.986755, 284.381744);

	float dot_x = dot(value, const_x) * TAU;
	float dot_y = dot(value, const_y) * TAU;

	float rand_x = fract(sin(dot_x) * combined_seed) * 2.0 - 1.0;
	float rand_y = fract(sin(dot_y) * combined_seed) * 2.0 - 1.0;

	vec2 abs_result = abs(vec2(rand_x, rand_y));

	random_result result;
	result.d1 = abs_result.x;
	result.d2 = abs_result;

	return result;
}

/* Per-cell random values: quantizes the UVs to a 10x10 grid before
 * hashing, so every cell of the grid shares one random value.
 *
 * 输出逐格随机值。先把 UV 量化到 10x10 网格再取随机，每个格子共享一个随机值。 */
random_result random_uvs(vec2 uv, float seed) {
	return random(ceil(uv * 10.0), seed);
}

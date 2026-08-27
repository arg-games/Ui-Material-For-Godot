// Ping-pong waves. Each wave repeats every 1.0 / subdivisions of the input.

struct ping_pong_result
{
	float result;
	float inverse_result;
};

/* Remaps a 0..1 input into a wave that rises and falls between 0 and
 * height. Each back-and-forth repeats every 1.0 / subdivisions of the
 * input. Returns both outputs of Ping Pong.
 *
 * 把 0 到 1 的输入重映射为在 0 与 height 之间升降的波。
 * 输入每经过 1.0 / subdivisions 完成一次往复。
 * 返回 Ping Pong 的 Result 与 Inverse result 输出。 */
ping_pong_result ping_pong(float value, float subdivisions, float height) {
	float x = value * subdivisions;
	float f = fract(x);

	float p = min(f, 1.0 - f) * 2.0;

	ping_pong_result result;
	result.result = p * height;
	result.inverse_result = ((1.0 - p) * height) - height + 1.0;

	return result;
}

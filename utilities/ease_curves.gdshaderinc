// Easing curves converted from the UE material functions.

/* Ease-in with a sine curve: slow start, fast end. Matches the
 * Ease In Sine output of Ease Curves.
 *
 * 正弦曲线缓入，起步慢，收尾快。
 * 对应 Ease Curves 的 Ease In Sine 输出。 */
float ease_in_sine(float value) {
	return 1.0 - cos(value * TAU * 0.25);
}

/* Ease-out with a sine curve: fast start, slow end. Matches the
 * Ease Out Sine output of Ease Curves.
 *
 * 正弦曲线缓出，起步快，收尾慢。
 * 对应 Ease Curves 的 Ease Out Sine 输出。 */
float ease_out_sine(float value) {
	return sin(value * TAU * 0.25);
}

/* Ease-in and out with a sine curve. Matches the Ease In Out Sine
 * output of Ease Curves.
 *
 * 正弦曲线缓入缓出。对应 Ease Curves 的 Ease In Out Sine 输出。 */
float ease_in_out_sine(float value) {
	return (1.0 - cos(value * TAU * 0.5)) * 0.5;
}

/* Ease-in on a cubic curve (power of 3). Matches the Ease In Cubic
 * output of Ease Curves.
 *
 * 三次曲线缓入。对应 Ease Curves 的 Ease In Cubic 输出。 */
float ease_in_cubic(float value) {
	return value * value * value;
}

/* Ease-out on a cubic curve (power of 3). Matches the Ease Out Cubic
 * output of Ease Curves.
 *
 * 三次曲线缓出。对应 Ease Curves 的 Ease Out Cubic 输出。 */
float ease_out_cubic(float value) {
	float inverse_value = 1.0 - value;

	return 1.0 - (inverse_value * inverse_value * inverse_value);
}

/* Ease-in and out on a cubic curve (power of 3). Matches the
 * Ease In Out Cubic output of Ease Curves.
 *
 * 三次曲线缓入缓出。对应 Ease Curves 的 Ease In Out Cubic 输出。 */
float ease_in_out_cubic(float value) {
	return (value < 0.5)
			? 4.0 * value * value * value
			: 1.0 - pow(-2.0 * value + 2.0, 3.0) * 0.5;
}

/* Ease-in on a quintic curve (power of 5), steeper than cubic. Matches
 * the Ease In Quintic output of Ease Curves.
 *
 * 五次曲线缓入，比三次更陡。
 * 对应 Ease Curves 的 Ease In Quintic 输出。 */
float ease_in_quint(float value) {
	return pow(value, 5.0);
}

/* Ease-out on a quintic curve (power of 5). Matches the Ease Out
 * Quintic output of Ease Curves.
 *
 * 五次曲线缓出。对应 Ease Curves 的 Ease Out Quintic 输出。 */
float ease_out_quint(float value) {
	return 1.0 - pow(1.0 - value, 5.0);
}

/* Ease-in and out on a quintic curve (power of 5). Matches the
 * Ease In Out Quintic output of Ease Curves.
 *
 * 五次曲线缓入缓出。对应 Ease Curves 的 Ease In Out Quintic 输出。 */
float ease_in_out_quint(float value) {
	return (value < 0.5)
			? 16.0 * pow(value, 5.0)
			: 1.0 - pow(-2.0 * value + 2.0, 5.0) * 0.5;
}

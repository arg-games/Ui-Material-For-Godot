// Time helpers converted from the UE material functions.

/* Loops the input value from 0 to 1 at the given speed. Matches the
 * 0-1 Loop output of Linear Time.
 *
 * 按给定速度把输入值从 0 循环到 1。
 * 对应 Linear Time 的 0-1 Loop 输出。 */
float loop_0_1(float value, float speed) {
	return fract(value * speed);
}

float loop_0_1(float speed) {
	return loop_0_1(TIME, speed);
}

/* Bounces the input value back and forth between 0 and 1. One round
 * trip lasts as long as one full loop at the same speed. Matches the
 * 0-1 Ping-Pong output of Linear Time.
 *
 * 让输入值在 0 和 1 之间往返。同速度下一次往返与一次完整循环等长。
 * 对应 Linear Time 的 0-1 Ping-Pong 输出。 */
float ping_pong_0_1(float value, float speed) {
	float loop_value = fract(value * speed);

	return 2.0 * min(loop_value, 1.0 - loop_value);
}

float ping_pong_0_1(float speed) {
	return ping_pong_0_1(TIME, speed);
}

/* Outputs 0 during the first half of each cycle and 1 during the second
 * half, like an off-on switch. Matches the 0-1 Switch output of Linear
 * Time.
 *
 * 每个周期前半段输出 0，后半段输出 1，类似开关。
 * 对应 Linear Time 的 0-1 Switch 输出。 */
float switch_0_1(float value, float speed) {
	return round(fract(value * speed));
}

float switch_0_1(float speed) {
	return switch_0_1(TIME, speed);
}

/* Sine wave driven by the input value scaled by speed. Output range is
 * -1..1.
 *
 * 输入值乘以速度后取正弦，输出范围是 -1 到 1。 */
float sine_time(float value, float speed) {
	return sin(value * speed * TAU);
}

float sine_time(float speed) {
	return sine_time(TIME, speed);
}

/* Same sine wave as sine_time, remapped from -1..1 to 0..1.
 *
 * 正弦波与 sine_time 相同，重映射到 0 到 1 区间。 */
float sine_time_0_1(float value, float speed) {
	return (sin(value * speed * TAU) * 0.5) + 0.5;
}

float sine_time_0_1(float speed) {
	return sine_time_0_1(TIME, speed);
}

/* Delays the input value by offset where round(uv.x) is 1, splitting
 * the space into an undelayed half and a delayed half. Matches Time
 * Displace with a binary mask.
 *
 * 在 round(uv.x) 为 1 的一侧把输入值延迟 offset，空间分成不延迟与延迟两半。
 * 相当于使用二值遮罩的 Time Displace。 */
float time_displace(float value, float offset, float mask) {
    return mix(value, value - offset, mask);
}
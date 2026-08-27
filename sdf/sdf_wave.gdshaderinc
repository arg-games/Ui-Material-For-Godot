#include "../time.gdshaderinc"
#include "../utilities/ping_pong.gdshaderinc"

struct sdf_wave_result
{
	float cosine;
	float frac;
	float ping_pong;
	float raw;
};

/* Expands a signed distance field into repeating waves, matching
 * MF_UI_Wave. The field moves by motion and repetitions multiplies the
 * result so each unit adds one wave cycle. Struct fields mirror the four
 * outputs: cosine is the smooth symmetrical wave remapped from -1..1 to
 * 0..1, frac is a sharp sawtooth, ping_pong is a symmetrical linear
 * triangle wave, and raw is the expanded value before shaping.
 *
 * 有向距离场扩展成重复的波，对应 MF_UI_Wave。
 * 距离场先按 motion 平移，再乘以 repetitions，每个单位增加一个波形周期。
 * 结构体四个字段与四个输出一一对应：cosine 是平滑的对称波，从 -1 到 1 重映射到 0 到 1；
 * frac 是尖锐的锯齿波；ping_pong 是对称的线性三角波；raw 是塑形前的扩展值。 */
sdf_wave_result sdf_wave(float sdf_input, float repetitions, float motion) {
	sdf_wave_result result;

	float expanded = (sdf_input - motion) * repetitions;

	result.raw = expanded;
	result.cosine = (cos(expanded) * 0.5) + 0.5;
	result.frac = fract(expanded);
	result.ping_pong = ping_pong(expanded, 1.0, 1.0).result;

	return result;
}

/* Defaults follow the UE graph's preview values: three repetitions and
 * motion looping from time at speed 0.5.
 *
 * 默认值取自 UE 图的预览值：三次重复，motion 以速度 0.5 随时间循环。 */
sdf_wave_result sdf_wave(float sdf_input) {
	return sdf_wave(sdf_input, 3.0, loop_0_1(0.5));
}

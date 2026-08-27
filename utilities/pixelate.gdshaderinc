/* Snaps coordinates into discrete cells, two-dimensional Posterize.
 * Pairs well with Grid Tiling and Random to vary values per cell.
 * Matches Pixelate.
 *
 * 把坐标吸附到离散格子，相当于二维的海报化。
 * 与网格平铺和随机函数搭配可做逐格变化。对应 Pixelate。 */
vec2 uv_pixelate(vec2 uv, float num_pixels) {
	return floor(uv * num_pixels) / num_pixels;
}

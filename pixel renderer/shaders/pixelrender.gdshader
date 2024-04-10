shader_type canvas_item;

uniform sampler2D screen_texture: source_color, repeat_disable, filter_nearest;
uniform sampler2D palette: source_color, filter_nearest;
uniform float spread;
uniform int colors;
uniform bool custom_pallete;

const mat4 bayer4 = mat4(
	vec4(0, 8, 2, 10),
	vec4(12, 4, 14, 6),
	vec4(3, 11, 1, 9),
	vec4(15, 7, 13, 5)
);

void fragment() {
	int x = int(UV.x * 1.0 / SCREEN_PIXEL_SIZE.x);
	int y = int(UV.y * 1.0 / SCREEN_PIXEL_SIZE.y);
	x %= 4;
	y %= 4;
	vec4 dithered = texture(screen_texture, UV) + spread * (bayer4[x][y] / 16.0 - 0.5);
	vec4 quantized = floor(dithered * float(colors - 1) + 0.5) / float(colors - 1) * texture(screen_texture, UV).a;
	float grayscale = (quantized.r + quantized.g + quantized.b) / 3.0;
	COLOR = custom_pallete ? vec4(texture(palette, vec2(grayscale, 0.5)).rgb, quantized.a) : quantized;
}
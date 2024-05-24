shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture: source_color, hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture: source_color, hint_depth_texture, filter_nearest;
uniform sampler2D palette: source_color, filter_nearest, repeat_disable;
uniform vec3 background_color: source_color;

group_uniforms quantization;
uniform float spread;
uniform int colors;
uniform bool custom_pallete;

group_uniforms outline;
uniform bool outline;
uniform float outline_threshold : hint_range(0, 1) = 0.01;
uniform vec3 outline_color: source_color;
uniform bool pallete_outline;

const mat4 bayer4 = mat4(
	vec4(0, 8, 2, 10),
	vec4(12, 4, 14, 6),
	vec4(3, 11, 1, 9),
	vec4(15, 7, 13, 5)
);

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

//get linearized depth
float get_depth(mat4 inv_proj_mat, vec2 uv) {
	float depth_tex = texture(depth_texture, uv).r;
	vec3 normalized_device = vec3(uv * 2.0 - 1.0, depth_tex);
	vec4 view = inv_proj_mat * vec4(normalized_device, 1.0);
	return -view.z / view.w;
}

vec4 color_quantize(vec2 screen_uv, vec2 viewport_size, bool gray) {
	int x = int(screen_uv.x * viewport_size.x) % 4;
	int y = int(screen_uv.y * viewport_size.y) % 4;
	vec4 dithered = texture(screen_texture, screen_uv) + (spread / (pow(2, 3))) * (bayer4[x][y] / 16.0 - 0.5);
	vec4 quantized = floor(dithered * float(colors - 1) + 0.5) / float(colors - 1) * texture(screen_texture, screen_uv).a;
	float grayscale = (quantized.r + quantized.g + quantized.b) / 3.0;
	if (gray) return vec4(vec3(grayscale), 1.0);
	return custom_pallete ? vec4(texture(palette, vec2(grayscale, 0.5)).rgb, quantized.a) : quantized;
}

void fragment() {
	vec4 original = texture(screen_texture, SCREEN_UV);
	vec4 color_quantized = color_quantize(SCREEN_UV, VIEWPORT_SIZE, false);
	
	float depth = get_depth(INV_PROJECTION_MATRIX, SCREEN_UV);
	vec2 texel_size = 1.0 / VIEWPORT_SIZE.xy;
	
	int non_transparent = 0;
	vec3 average_color = vec3(0.0);
	float depth_difference = 0.0;
	for (int i = 0; i < 4; i++) {
		float x = SCREEN_UV.x + texel_size.x * float(i / 2 == 0 ? i * 2 - 1 : 0);
		float y = SCREEN_UV.y + texel_size.y * float(i / 2 == 1 ? (i - 2) * 2 - 1 : 0);
		float d = get_depth(INV_PROJECTION_MATRIX, vec2(x, y));
		vec4 c = color_quantize(vec2(x, y), VIEWPORT_SIZE, true);
		depth_difference += depth - d;
		average_color += c.rgb * c.a;
		non_transparent += int(c.a == 1.0);
	}
	average_color /= float(non_transparent);
	
	float final_depth = step(outline_threshold, depth_difference);
	float alpha = clamp(original.a + (outline ? final_depth : 0.0), 0.0, 1.0);
	float reverse_grayscale = abs(average_color.r - 1.0);
	vec3 reverse_color = texture(palette, vec2(pow(reverse_grayscale, 10), 0.5)).rgb;
	vec3 outline_added = mix(color_quantized.rgb, pallete_outline ? reverse_color : outline_color, final_depth);
	
	ALBEDO = outline ? vec3(outline_added) : color_quantized.rgb;
	ALBEDO = alpha > 0.0 ? ALBEDO : background_color;
}
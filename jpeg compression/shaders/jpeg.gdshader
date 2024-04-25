shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture;
uniform float quality : hint_range(1, 100, 1) = 50;
uniform int color_compression : hint_range(1, 4, 1) = 1;

const mat3 rgb_to_ycbcr = mat3(
	vec3(0.299, 0.587, 0.114),
	vec3(-0.169, -0.331, 0.5),
	vec3(0.5, -0.419, -0.081)
);

const mat3 ycbcr_to_rgb = mat3(
	vec3(1.0, 0.0, 1.4),
	vec3(1.0, -0.343, -0.711),
	vec3(1.0, 1.765, 0.0)
);

const int[64] base_compression = {
	16, 11, 10, 16, 24, 40, 51, 61,
	12, 12, 14, 19, 26 ,58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
	14, 17, 22, 29, 51, 87, 80, 62,
    18, 22, 37, 56, 68, 109, 103, 77,
	24, 35, 55, 64, 81, 104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
	72, 92, 95, 98, 112, 100, 103, 99
};

const int[64] compression = {
	112,84,98,98,126,168,343,504,
	77,84,91,119,154,245,448,644,
	70,98,112,154,259,385,546,665,
	112,13,168,203,392,448,609,686,
	168,182,280,357,476,567,721,784,
	280,406,399,609,763,728,847,700,
	357,420,483,560,721,791,840,721,
	427,385,392,434,539,644,707,693
};

varying int[64] kernel;
varying float[64] g;

float a(int u) {
	return u == 0 ? 1.0 / sqrt(2) : 1.0;
}

int quantization(int i) {
	int s = 0;
	if (quality < 50.0) {
		s = int(5000.0 / quality);
	} else {
		s = int(200.0 - 2.0 * quality);
	}
	
	int index = int((s * base_compression[i] + 50) / 100); 
	return index != 0 ? index : 1;
}

void fragment() {
	float res_x = 1.0/SCREEN_PIXEL_SIZE.x;
	float res_y = 1.0/SCREEN_PIXEL_SIZE.y;
	
	float uv_x = trunc(UV.x * res_x/8.0) / (res_x/8.0);
	float uv_y = trunc(UV.y * res_y/8.0) / (res_y/8.0);
	vec2 new_uv = vec2(uv_x, uv_y);
	
	int x = int(UV.x * res_x) % 8;
	int y = int(UV.y * res_y) % 8;
	
	// convert to ycc and compress color channels
	float c_uv_x = trunc(UV.x * res_x/float(color_compression)) / (res_x/float(color_compression));
	float c_uv_y = trunc(UV.y * res_y/float(color_compression)) / (res_y/float(color_compression));
	vec2 c_new_uv = vec2(c_uv_x, c_uv_y);
	vec3 color = vec3(0.0);
	for (int i = 0; i < color_compression; i++) {
		for (int j = 0; j < color_compression; j++) {
			color += texture(screen, c_new_uv + vec2(float(i)/res_x, float(j)/res_y)).rgb;
		}
	}
	
	color = color / float(color_compression * color_compression) * 255.0 * rgb_to_ycbcr + vec3(0.0, 128.0, 128.0);
	
	// convert into 8x8 matrix of y value from rgb->y,cb,cr conversion
	for (int i = 0; i < 64; i++) {
		kernel[i] = int((texture(screen, new_uv + vec2(float(i % 8)/res_x, float(i / 8)/res_y)).rgb * rgb_to_ycbcr).r * 255.0);
		kernel[i] -= 128;
	}
	
	// perform dct on matrix
	for (int i = 0; i < 64; i++) {
		int u = i % 8;
		int v = i / 8;
		float sum = 0.0;
		for (int x = 0; x < 8; x++) {
			for (int y = 0; y < 8; y++) {
				sum += float(kernel[x + y * 8]) * cos((2.0 * float(x) + 1.0) * float(u) * PI / 16.0) * cos((2.0 * float(y) + 1.0) * float(v) * PI / 16.0);
			}
		}
		g[i] = a(u) * a(v) * sum / 4.0;
		
		// compress based on quantization matrix
		g[i] = round(g[i] / float(quantization(i)));
		g[i] *= float(quantization(i));
	}
	
	// inverse dct
	float sum = 0.0;
	for (int u = 0; u < 8; u++) {
		for (int v = 0; v < 8; v++) {
			sum += a(u) * a(v) * g[v * 8 + u] * cos((2.0 * float(x) + 1.0) * float(u) * PI / 16.0) * cos((2.0 * float(y) + 1.0) * float(v) * PI / 16.0);
		}
	}
	sum *= 0.25;
	int final = int(round(sum));
	
	// convert back to rgb
	vec3 final_color = vec3(float(final) + 128.0, color.g - 128.0, color.b - 128.0);
	COLOR = vec4(final_color * ycbcr_to_rgb / 255.0, 1.0);
}
shader_type canvas_item;

uniform sampler2D screen_texture;
uniform int kernel_size;
uniform float gaussian_sigma;
uniform float k;

float gaussian(float sigma, float pos)	 {
	return (1.0 / sqrt(2.0 * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0 * sigma * sigma));
}

// ?? idk man 
float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 col = vec2(0.0);
    float kernel_sum_1 = 0.0;
	
        for (int x = -kernel_size; x <= kernel_size; ++x) {
            float c = luminance(texture(screen_texture, UV + vec2(float(x), 0.0) * SCREEN_PIXEL_SIZE.xy).rgb);
            float gauss1 = gaussian(gaussian_sigma, float(x));

            col.r += c * gauss1;
            kernel_sum_1 += gauss1;
        }
		
    COLOR = vec4(vec3(col.r / kernel_sum_1), 1.0);
}
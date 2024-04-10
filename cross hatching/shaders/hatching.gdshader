shader_type canvas_item;

uniform bool shader_off;

group_uniforms textures;
uniform sampler2D original_texture;
uniform sampler2D screen_texture;

group_uniforms thresholding;
uniform float tau;
uniform float threshold;
uniform bool thresholding;
uniform float phi;
uniform bool tanh_smoothing;

group_uniforms hatching.colored_hatching;
uniform bool colored_hatch;
uniform float saturation;
uniform float blend_strength: hint_range(0.0, 1.0);
group_uniforms;

group_uniforms hatching.thresholds;
uniform float hatching_threshold_1;
uniform float hatching_threshold_2;
uniform float hatching_threshold_3;
uniform float hatching_threshold_4;
group_uniforms;

group_uniforms hatching.rotations;
uniform float hatching_rotation_1;
uniform float hatching_rotation_2;
uniform float hatching_rotation_3;
uniform float hatching_rotation_4;
group_uniforms;

group_uniforms hatching.toggles;
uniform bool hatching_toggle_1;
uniform bool hatching_toggle_2;
uniform bool hatching_toggle_3;
uniform bool hatching_toggle_4;
group_uniforms;

group_uniforms hatching;
uniform bool hatching;
uniform sampler2D hatching_texture: repeat_enable;
uniform float hatching_resolution;

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 gaussian = texture(screen_texture, UV).rg;
	vec4 dog = vec4((1.0 + tau) * gaussian.r - tau * gaussian.g);
	
    if (thresholding) {
        if (tanh_smoothing) {
            dog = (dog.r >= threshold) ? vec4(1.0) : 1.0 + tanh(phi * (dog - threshold));
        }
		else if (hatching) {
			dog.r = (dog.r >= hatching_threshold_1) ? 1.0 : 0.0;
			dog.g = (dog.g >= hatching_threshold_2) ? 1.0 : 0.0;
			dog.b = (dog.b >= hatching_threshold_3) ? 1.0 : 0.0;
			dog.a = (dog.a >= hatching_threshold_4) ? 1.0 : 0.0;
		} else {
            dog = (dog.r >= threshold) ? vec4(1.0) : vec4(0.0);
		}
    }
	
	vec4 output = dog;
	
	if (hatching) {
		output = vec4(0.0);
		
		//hatching
		vec2 hatch_uv = UV * 2.0 - 1.0;
		if (hatching_toggle_1) {
			float radian = -55.0 * PI / 180.0;
			mat2 rot = mat2(
				vec2(cos(radian), -sin(radian)),
				vec2(sin(radian), cos(radian))
			);
			vec3 layer1 = texture(hatching_texture, rot * (hatch_uv * hatching_resolution) * 0.5 + 0.5).rgb;
			output.rgb = mix(layer1, vec3(1.0), dog.r);
		}
		
		if (hatching_toggle_2) {
			float radian2 = 5.0 * PI / 180.0;
			mat2 rot2 = mat2(
				vec2(cos(radian2), -sin(radian2)),
				vec2(sin(radian2), cos(radian2))
			);
			vec3 layer2 = texture(hatching_texture, rot2 * (hatch_uv * hatching_resolution) * 0.5 + 0.5).rgb;
			output.rgb *= mix(layer2, vec3(1.0), dog.g);
		}
		
		if (hatching_toggle_3) {
			float radian3 = -10.0 * PI / 180.0;
			mat2 rot3 = mat2(
				vec2(cos(radian3), -sin(radian3)),
				vec2(sin(radian3), cos(radian3))
			);
			vec3 layer3 = texture(hatching_texture, rot3 * (hatch_uv * hatching_resolution) * 0.5 + 0.5).rgb;
			output.rgb *= mix(layer3, vec3(1.0), dog.b);
		}
		
		if (hatching_toggle_4) {
			float radian4 = -25.0 * PI / 180.0;
			mat2 rot4 = mat2(
				vec2(cos(radian4), -sin(radian4)),
				vec2(sin(radian4), cos(radian4))
			);
			vec3 layer4 = texture(hatching_texture, rot4 * (hatch_uv * hatching_resolution) * 0.5 + 0.5).rgb;
			output.rgb *= mix(layer4, vec3(1.0), dog.a);
		}
		
		if (colored_hatch) {
		 	vec3 coloredPencil = texture(original_texture, UV).rgb;
	        coloredPencil = mix(vec3(luminance(coloredPencil)), coloredPencil, saturation);
	        coloredPencil = mix(coloredPencil, vec3(1.0), output.rgb);

	        output = vec4(mix(texture(original_texture, UV).rgb, coloredPencil, blend_strength), 1.0);
		}
	}
    COLOR = mix(vec4(output.rgb, 1.0), texture(original_texture, UV), float(shader_off));
}
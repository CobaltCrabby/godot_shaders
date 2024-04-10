shader_type spatial;
render_mode cull_disabled, unshaded;

varying float height;
uniform float frequency;
uniform sampler2D color_texture : filter_nearest, repeat_disable, source_color;

vec2 rotate_vector(vec2 vec, float theta) {
	return vec2(cos(theta) * vec.x - sin(theta) * vec.y, sin(theta) * vec.x + cos(theta) * vec.y);
}

float hash(float id) {
	return fract(sin(id) * 43758.5453123);
}

void vertex() {
	height = 1.0 + (INSTANCE_CUSTOM.a * 2.5 - 0.5);
	VERTEX.y += abs(UV.y - 1.0) * height;
	VERTEX.y += INSTANCE_CUSTOM.b * 5.0;
	
	float theta = INSTANCE_CUSTOM.g;
	highp float hash = hash(INSTANCE_CUSTOM.r);
	float wave = 0.0;
	
	if (hash < 0.3) {
		wave = cos((TIME + hash * 2.0) * frequency * 0.8);
	} else {
		wave = (cos(TIME * (frequency - height)) * cos(TIME * (frequency - height)) * 0.65 - hash) * 0.8;
	}
	vec2 displacement = vec2(wave * height * (hash + 0.1) * 0.6);
	VERTEX.xz += rotate_vector(displacement, theta) * abs(UV.y - 1.0);
}

void fragment() {
	vec4 color = texture(color_texture, UV);
	if (color.a < 1.0) {
		discard;
	}
	ALBEDO = mix(color.rgb, vec3(117.0/255.0, 171.0/255.0, 60.0/255.0), pow(abs(UV.y - 1.0), 5.0) * ((height - 0.5) / 3.0 + 1.0));
}
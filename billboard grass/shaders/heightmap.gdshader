shader_type spatial;

uniform sampler2D height_map;
uniform sampler2D normal_map;
uniform float scale;
uniform float normal_scale;
uniform float height;
uniform vec3 color: source_color;

void vertex() {
	VERTEX.y += texture(height_map, UV / scale).r * height;
	NORMAL = texture(normal_map, UV * normal_scale).rgb;
}

void fragment() {
	ALBEDO = color;
}
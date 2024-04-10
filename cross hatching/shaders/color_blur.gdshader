shader_type canvas_item;

uniform sampler2D hatched_texture;
uniform sampler2D blurred_texture;
uniform float brightness;

void fragment() {
	COLOR = vec4(texture(hatched_texture, UV).rgb * texture(blurred_texture, UV).rgb, 1.0) * brightness;
}

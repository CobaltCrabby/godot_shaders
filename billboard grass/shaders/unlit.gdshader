shader_type canvas_item;

uniform sampler2D albedo;

void fragment() {
	COLOR = texture(albedo, UV);
}
shader_type spatial;

group_uniforms Foam;
uniform sampler2D foam_tex;
uniform float foam_alpha;
uniform float foam_speed;
uniform vec3 foam_color : source_color;

group_uniforms Distortion;
uniform sampler2D distortion_noise;
uniform float distortion_intensity;
uniform float distortion_speed;

group_uniforms Overlay;
uniform sampler2D overlay_noise;
uniform float overlay_speed;
uniform float overlay_alpha;
uniform float overlay_cutoff;
uniform vec3 overlay_color : source_color;

group_uniforms General;
uniform float scale;
uniform float pixelization;
uniform float base_alpha;
uniform vec3 base_color : source_color;

//both stole from unity lol
vec2 blend_sub(vec2 Base, vec2 Blend, float Opacity){
    vec2 Out = Base - Blend;
    Out = mix(Base, Out, Opacity);
	return Out;
}

vec3 blend_mul(vec3 Base, vec3 Blend, float Opacity){
    vec3 Out = Base * Blend;
    Out = mix(Base, Out, Opacity);
	return Out;
}

void fragment() {
	vec2 pixelized_uv = round(UV * pixelization) / pixelization * scale;
	
	float distortion_tex = texture(distortion_noise, pixelized_uv + TIME * distortion_speed).r;
	vec2 distortion = blend_sub(pixelized_uv, vec2(distortion_tex), distortion_intensity);
	float foam = texture(foam_tex, distortion + TIME * foam_speed).a;
	
	float overlay = step(texture(overlay_noise, pixelized_uv + TIME * overlay_speed).r, 1.0);
	ALBEDO = blend_mul(base_color + foam * foam_alpha, overlay * overlay_color, overlay_alpha);
	//ALBEDO = base_color + foam * foam_alpha - overlay * overlay_color * overlay_alpha;
	ALPHA = base_alpha;
}
#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, binding = 0) restrict uniform image2D texture;

void main() {
    ivec2 coords = ivec2(gl_GlobalInvocationID.xy);
    imageStore(texture, coords, vec4(gl_GlobalInvocationID.x / 8.0, gl_GlobalInvocationID.y / 8.0, 1.0, 1.0));
}
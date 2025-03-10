#[compute]
#version 450

// 1x1x1 unless i wanna do a parallel reduction add (maybe later)
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

layout (push_constant, std430) uniform Params {
    vec2 raster_size;
    float quality;
    uint color_compression;
} params;

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

const int[8][8] base_compression = {
	{16, 11, 10, 16, 24, 40, 51, 61},
	{12, 12, 14, 19, 26 ,58, 60, 55},
	{14, 13, 16, 24, 40, 57, 69, 56},
	{14, 17, 22, 29, 51, 87, 80, 62},
	{18, 22, 37, 56, 68, 109, 103, 77},
	{24, 35, 55, 64, 81, 104, 113, 92},
	{49, 64, 78, 87, 103, 121, 120, 101},
	{72, 92, 95, 98, 112, 100, 103, 99}
};

const float PI = 3.14159265f;

float a(int u) {
	return u == 0 ? 1.0 / sqrt(2) : 1.0;
}

int quantization(int x, int y) {
	int s = 0;
	if (params.quality < 50.0) {
		s = int(5000.0 / params.quality);
	} else {
		s = int(200.0 - 2.0 * params.quality);
	}
	
	int index = int((s * base_compression[x][y] + 50) / 100); 
	return index != 0 ? index : 1;
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy) * 8;
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    // create kernel with ycc conversion
    int kernel[8][8];
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            vec3 value = imageLoad(color_image, uv + ivec2(i, j)).rgb * rgb_to_ycbcr;
            kernel[i][j] = int(value.r * 255) - 128;
        }
    }

    // perform dct
    float dctMat[8][8];
    for (int u = 0; u < 8; u++) {
		for (int v = 0; v < 8; v++) {
            float sum = 0.f;
            for (int x = 0; x < 8; x++) {
                for (int y = 0; y < 8; y++) {
                    sum += kernel[x][y] * cos((2.f * x + 1.f) * u * PI / 16.f) * cos((2.f * y + 1.f) * v * PI / 16.f);
                }
            }

            dctMat[u][v] = 0.25f * a(u) * a(v) * sum;
            dctMat[u][v] = round(dctMat[u][v] / quantization(u, v));
            dctMat[u][v] *= quantization(u, v);
        }
	}

    // perform inverse dct
    // pixel loops
    for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
            float sum = 0.f;

            // matrix loops
            for (int u = 0; u < 8; u++) {
                for (int v = 0; v < 8; v++) {
                    sum += a(u) * a(v) * dctMat[u][v] * cos((2.f * x + 1.f) * u * PI / 16.f) * cos((2.f * y + 1.f) * v * PI / 16.f);
                }
            }
            sum *= 0.25f;

            int final = int(round(sum));
            vec3 color = imageLoad(color_image, uv + ivec2(x, y)).rgb * 255.0 * rgb_to_ycbcr + vec3(0.f, 128.f, 128.f);

            vec3 finalColor = vec3(final + 128.f, color.g - 128.f, color.b - 128.f);
            finalColor = vec3(finalColor * ycbcr_to_rgb) / 255.f;
            imageStore(color_image, uv + ivec2(x, y), vec4(finalColor, 1.f));
        }
    }
}
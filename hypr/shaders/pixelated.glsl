#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float raw_pixel_count = 350.0;
const float aspect_ratio    = 16.0 / 9.0;

void main() {
    // Calculate pixel dimensions -> account for aspect ratio
    vec2 pixel_count  = vec2(raw_pixel_count * aspect_ratio, raw_pixel_count);
    vec2 pixel_size   = 1.0 / pixel_count;
    vec2 pixel_coord  = floor(v_texcoord * pixel_count) + 0.5;
    vec2 sample_coord = pixel_coord / pixel_count;

    fragColor = texture(tex, sample_coord);
}

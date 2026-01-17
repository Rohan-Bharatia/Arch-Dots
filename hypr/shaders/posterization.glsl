#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float color_levels = 4.0;
const bool use_dithering = true;

float bayer_dither(vec2 pos) {
    ivec2 p = ivec2(mod(pos, 4.0));
    int idx = p.x + p.y * 4.0;
    float matrix[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );
    return (matrix[idx] / 16.0) - 0.5;
}

void main() {
    vec4 color = texture(tex, v_texcoord);

    vec3 posterized;
    if (use_dithering) {
        float dither = bayer_dither(gl_FragCoord.xy);
        posterized = floor((color.rgb + dither) * color_levels + 0.5) / color_levels;
    } else {
        posterized = floor(color.rgb * color_levels + 0.5) / color_levels;
    }
    posterized = clamp(posterized, 0.0, 1.0);

    fragColor = vec4(posterized, color.a);
}

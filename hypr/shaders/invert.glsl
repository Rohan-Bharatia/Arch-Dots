#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const vec3 luma               = vec3(0.2126, 0.7152, 0.0722);
const bool preserve_luminance = false;

void main() {
    vec4 color    = texture(col, v_texcoord);
    vec3 inverted = 1.0 - color.rgb;

    if (preserve_luminance) {
        float orig_luma     = dot(color.rgb, luma);
        float inverted_luma = dot(inverted.rgb, luma);
        if (inverted_luma > 0.001) {
            inverted *= orig_luma / inverted_luma;
            inverted  = clamp(inverted, 0.0, 1.0);
        }
    }

    fragColor = vec4(inverted, color.a);
}

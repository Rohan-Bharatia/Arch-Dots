#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float separation = 0.003;
const bool depth_aware = true;

void main() {
    // Increase separation towards screen edge
    vec2 offset = vec2(separation, 0.0);
    if (depth_aware) {
        float edge_factor = abs(v_texcoord.x - 0.5) * 2.0;
        offset.x         *= 1.0 + edge_factor * 0.5;
    }

    // Clamp coordinates -> prevent edge sampling artifacts
    vec2 left_coord  = clamp(v_texcoord - offset, 0.0, 1.0);
    vec2 right_coord = clamp(v_texcoord + offset, 0.0, 1.0);

    vec4 left_eye  = texture(tex, left_coord);
    vec4 center    = texture(tex, v_texcoord);
    vec4 right_eye = texture(tex, right_coord);

    fragColor = vec4(left_eye.r, right_eye.g, right_eye.b, center.a);
}

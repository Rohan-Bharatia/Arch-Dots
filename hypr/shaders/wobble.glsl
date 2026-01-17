#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;
uniform float time;

out vec4 fragColor;

const float pi                     = 3.14159265359;
const float wobble_speed           = 3.0;
const float wobble_frequency       = 15.0;
const float wobble_amplitude       = 0.025;
const float edge_fade              = 0.1;
const bool  organic_motion         = true;
const bool  prevent_edge_artifacts = true;

void main() {
    float t = mod(time, 2 * pi * 100);
    vec2 uv = v_texcoord;

    // Calculate edge mask fade
    float edge_mask = 1.0;
    if (edge_fade > 0.0) {
        vec2 edge_dist = min(v_texcoord, 1.0 - v_texcoord);
        float min_dist = min(edge_dist.x, edge_dist.y);
        edge_mask      = smoothstep(0.0, edge_fade, min_dist);
    }

    float amplitude = wobble_amplitude * edge_mask;
    float h_offset, w_offset;
    if (organic_motion) {
        // Layer multiple frequencies for organic motion
        h_offset  = 0.0;
        h_offset += sin(v_texcoord.y * wobble_frequency * 1.0 + t * wobble_speed * 1.00) * 0.50;
        h_offset += sin(v_texcoord.y * wobble_frequency * 2.1 + t * wobble_speed * 1.37) * 0.30;
        h_offset += sin(v_texcoord.y * wobble_frequency * 0.5 + t * wobble_speed * 0.71) * 0.20;

        v_offset  = 0.0;
        v_offset += cos(v_texcoord.x * wobble_frequency * 0.9 + t * wobble_speed * 1.13) * 0.50;
        v_offset += cos(v_texcoord.x * wobble_frequency * 1.7 + t * wobble_speed * 0.83) * 0.30;
        v_offset += cos(v_texcoord.x * wobble_frequency * 0.4 + t * wobble_speed * 1.41) * 0.20;

        h_offset += sin(v_texcoord.x * wobble_frequency * 0.3 + t * wobble_speed * 0.5) * 0.1;
        v_offset += cos(v_texcoord.y * wobble_frequency * 0.3 + t * wobble_speed * 0.6) * 0.1;
    } else {
        // Single frequency wobble
        h_offset = sin(v_texcoord.y * wobble_frequency + t * wobble_speed);
        v_offset = cos(v_texcoord.x * wobble_frequency + t * wobble_speed);
    }

    uv.x += h_offset * amplitude;
    uv.y += v_offset * amplitude;
    if (prevent_edge_artifacts) {
        uv = clamp(uv, 0.002, 0.998);
    }

    fragColor = texture(tex, uv);
}

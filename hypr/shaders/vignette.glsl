#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float radius   = 0.85;
const float softness = 0.85;
const float strength = 0.8;

void main() {
    vec4 color = texture(tex, v_texcoord);

    // Calculate vignette
    float dist     = distance(v_texcoord, vec2(0.5));
    float vignette = smoothstep(radius, radius - softness, dist);

    fragColor = vec4(mix(color.rgb, color.rgb * vignette, strength), color.a);
}

#version 300 es
precision highp float;

in vec2 v_texcoord;

out vec4 fragColor;

const float radius       = 0.65;
const float softness     = 0.45;
const float strength     = 0.5;
const float aspect_ratio = 16.0 / 9.0;

void main() {
    vec4 color = texture(tex, v_texcoord);

    // Aspect ratio distance correction
    vec2 centered = v_texcoord - 0.5;
    centered.x   *= aspect_ratio;
    float dist    = length(centered);
    dist         /= length(vec2(aspect_ratio * 0.5, 0.5));

    // Fix smoothstep bounds
    float outer_edge = radius + softness;
    float vignette   = 1.0 - smoothstep(radius, outer_edge, dist);

    fragColor = vec4(mix(color.rgb, color.rgb * vignette, strength), color.a);
}

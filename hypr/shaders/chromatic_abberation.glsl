#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float strength         = 0.01;
const float aspect_ratio     = 16.0 / 9.0;
const bool quadratic_falloff = true;

void main() {
    // Calculate offset magnitude
    vec2 center_dist = v_texcoord - 0.5;
    center_dist.x   *= aspect_ratio;
    float dist       = length(center_dist);
    float falloff    = dist * (quadratic_falloff ? dist : 1.0);

    // Normalize direction & apply strength
    vec2 dir    = normalize(center_dist + 0.0001);
    vec2 offset = dir * falloff * strength;
    offset.x /= aspect_ratio;

    vec2 red_coord  = clamp(v_texcoord - offset, 0.0, 1.0);
    vec2 blue_coord = clamp(v_texcoord + offset, 0.0, 1.0);

    vec4 center_pixel = texture(tex, v_texcoord);
    vec3 red          = texture(tex, red_coord).r;
    float green       = center_pixel.g;
    vec3 blue         = texture(tex, blue_coord).b;

    fragColor = vec4(red, green, blue, center_pixel.a);
}

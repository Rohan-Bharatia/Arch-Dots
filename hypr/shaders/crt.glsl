#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float curvature         = 3.5;
const float scanline_strength = 0.25;
const float screen_height     = 1080.0;
const float scanline_count    = 540.0;
const float aberration        = 0.002;
const float vignette_radius   = 1.00;
const float vignette_softness = 0.45;
const float glow              = 0.03;

vec2 curve_uv(vec2 uv) {
    uv          = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.xy) / vec2(curvature);
    uv          = uv + uv * offset * offset;
    uv          = uv * 0.5 + 0.5;
    return uv;
}

void main() {
    vec2 uv = curve_uv(v_texcoord);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 center_dist  = uv - 0.5;
    vec2 abber_offset = center_dist * abberation;
    vec3 color        = texture(tex, clamp(uv + aberr_offset, 0.0, 1.0)).rgb;
    color.g           = texture(tex, uv).g;

    // Anti-alias scanlines w/ a triangle wave
    float scanline_phase  = uv.y * scanline_count * 2.0;
    float scanline        = abs(fract(scanline_phase) - 0.5) * 2.0;
    scanline              = smoothstep(0.0, 1.0, scanline);
    float scanline_factor = 1.0 - (scanline_strength * (1.0 - scanline));
    color                *= scanline_factor;

    color         += glow * (1.0 - scanline);
    float dist     = length(center_dist) * 2.0;
    float vignette = 1.0 - smoothstep(vignette_radius,
                                      vignette_radius + vignette_softness,
                                      dist);
    color         *= vignette * 1.1;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

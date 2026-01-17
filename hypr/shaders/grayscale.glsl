#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const vec3 luma          = vec3(0.2126, 0.7152, 0.0722);
const bool gamma_correct = true;

float to_linear(float c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

float to_srgb(float c) {
    return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

void main() {
    vec4 pixel_color = texture(tex, v_texcoord);

    float gray;
    if (gamma_correct) {
        vec3 linear     = vec3(to_linear(pixel_color.r),
                               to_linear(pixel_color.g),
                               to_linear(pixel_color.b));
        float luminance = dot(linear, luma);
        gray            = to_srgb(luminance);
    } else {
        gray = dot(pixel_color.rgb, luma);
    }

    fragColor = vec4(vec3(gray), pixel_color.a);
}

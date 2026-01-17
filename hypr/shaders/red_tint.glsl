#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const vec3 luma = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 pixel = texture(tex, v_texcoord);
    float gray = dot(pixel.rgb, luma);
    fragColor  = vec4(gray, 0.0, 0.0, pixel.a);
}

#version 300 es
precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

const float intensity   = 1.0;
const mat3 sepia_matrix = mat3(
    0.393, 0.769, 0.189,
    0.349, 0.686, 0.168,
    0.272, 0.534, 0.131
);

void main() {
    vec4 color = texture(tex, v_texcoord);
    vec3 sepia = color.rgb * sepia_matrix;
    sepia      = clamp(sepia, 0.0, 1.0);
    vec3 blend = mix(color.rgb, sepia, intensity);

    fragColor = vec4(blend, color.a);
}

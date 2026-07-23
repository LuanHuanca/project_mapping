#version 330 core
in vec2 v_uv;
out vec4 FragColor;

uniform sampler2D u_texture;
uniform vec4 u_color;
uniform float u_opacity;
uniform int u_has_texture;

void main() {
    vec4 baseColor = u_color;
    if (u_has_texture == 1) {
        baseColor = texture(u_texture, v_uv);
    }
    FragColor = vec4(baseColor.rgb, baseColor.a * u_opacity);
}

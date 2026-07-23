#version 330 core
in vec2 v_uv;
out vec4 FragColor;

uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;

void main() {
    float toggle = step(0.5, fract(u_time * u_speed * 10.0));
    vec3 color = u_color.rgb * toggle;
    FragColor = vec4(color, u_color.a * u_opacity * toggle);
}

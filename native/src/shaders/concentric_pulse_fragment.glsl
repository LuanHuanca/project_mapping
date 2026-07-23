#version 330 core
in vec2 v_uv;
out vec4 FragColor;

uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;

void main() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(v_uv, center);
    float wave = sin((dist * 20.0) - (u_time * u_speed * 5.0));
    float intensity = smoothstep(0.2, 0.8, wave);

    vec3 color = u_color.rgb * intensity;
    FragColor = vec4(color, u_color.a * u_opacity * intensity);
}

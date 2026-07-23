#version 330 core
in vec2 v_uv;
out vec4 FragColor;

uniform float u_time;
uniform float u_speed;
uniform float u_opacity;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    float hue = fract(v_uv.x + v_uv.y + u_time * u_speed * 0.5);
    vec3 color = hsv2rgb(vec3(hue, 1.0, 1.0));
    FragColor = vec4(color, u_opacity);
}

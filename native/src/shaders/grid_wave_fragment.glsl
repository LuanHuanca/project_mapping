#version 330 core
in vec2 v_uv;
out vec4 FragColor;

uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;

void main() {
    vec2 grid = sin(v_uv * 30.0 + u_time * u_speed * 4.0);
    float lineVal = step(0.9, grid.x) + step(0.9, grid.y);
    float alpha = clamp(lineVal, 0.0, 1.0) * u_opacity;

    FragColor = vec4(u_color.rgb, alpha);
}

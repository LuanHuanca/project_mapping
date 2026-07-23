#version 330 core
in vec2 v_uv;
out vec4 FragColor;

uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;

void main() {
    float borderX = step(v_uv.x, 0.05) + step(0.95, v_uv.x);
    float borderY = step(v_uv.y, 0.05) + step(0.95, v_uv.y);
    float isEdge = clamp(borderX + borderY, 0.0, 1.0);

    float pulse = sin((v_uv.x + v_uv.y + u_time * u_speed) * 10.0) * 0.5 + 0.5;
    float alpha = isEdge * pulse * u_opacity;

    FragColor = vec4(u_color.rgb, alpha);
}

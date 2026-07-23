#version 330 core
layout (location = 0) in vec2 aPos;

uniform mat3 u_homography;
out vec2 v_uv;

void main() {
    v_uv = aPos;
    vec3 pos = u_homography * vec3(aPos.x * 2.0 - 1.0, (1.0 - aPos.y) * 2.0 - 1.0, 1.0);
    gl_Position = vec4(pos.xy / pos.z, 0.0, 1.0);
}

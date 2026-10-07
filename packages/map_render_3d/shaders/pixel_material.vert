#version 460 core

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
in vec3 vertexNormal;

#include <flame_3d/skinning.glsl>

out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragPosition;
out vec3 fragNormal;

uniform VertexInfo {
    mat4 model;
    mat4 view;
    mat4 projection;
} vertex_info;

void main() {
    mat4 transform = vertex_info.model * computeSkinMatrix();
    vec4 world = transform * vec4(vertexPosition, 1.0);
    gl_Position = vertex_info.projection * vertex_info.view * world;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragPosition = world.xyz;
    fragNormal = mat3(transform) * vertexNormal;
}

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

uniform PointDepth {
    vec4 positionRadius;
    vec4 tile;
} point_depth;

void main() {
    mat4 transform = vertex_info.model * computeSkinMatrix();
    vec4 world = transform * vec4(vertexPosition, 1.0);
    vec4 clip = vertex_info.projection * vertex_info.view * world;
    clip.x = clip.x / 3.0 + (-1.0 + (point_depth.tile.x + 0.5) * 2.0 / 3.0) * clip.w;
    clip.y = clip.y / point_depth.tile.w + (1.0 - (point_depth.tile.y + 0.5) * 2.0 / point_depth.tile.w) * clip.w;
    gl_Position = clip;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragPosition = world.xyz;
    fragNormal = mat3(transform) * vertexNormal;
}

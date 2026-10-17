#version 460 core

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
in vec3 vertexNormal;

#include <flame_3d/skinning.glsl>
#include "ground_depth.glsl"

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
    vec4 liftedWorld = transform * vec4(vertexPosition + vertexNormal, 1.0);
    vec4 clip = vertex_info.projection * vertex_info.view * world;
    vec4 liftedClip = vertex_info.projection * vertex_info.view * liftedWorld;
    if (clip.w > 0.000001 && liftedClip.w > 0.000001 && clip.z >= 0.0 && clip.z <= clip.w) {
        clip.z = boundedGroundDepth(clip.z / clip.w, liftedClip.z / liftedClip.w) * clip.w;
    }
    gl_Position = clip;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragPosition = world.xyz;
    fragNormal = vec3(0.0, 1.0, 0.0);
}

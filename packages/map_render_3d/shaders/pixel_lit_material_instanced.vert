#version 460 core

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
in vec3 vertexNormal;
in vec4 instanceModel0;
in vec4 instanceModel1;
in vec4 instanceModel2;
in vec4 instanceModel3;

out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragPosition;
out vec3 fragNormal;
out float fragViewDepth;

uniform VertexInfo {
    mat4 view;
    mat4 projection;
} vertex_info;

void main() {
    mat4 transform = mat4(instanceModel0, instanceModel1, instanceModel2, instanceModel3);
    vec4 world = transform * vec4(vertexPosition, 1.0);
    gl_Position = vertex_info.projection * vertex_info.view * world;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragPosition = world.xyz;
    fragViewDepth = -(vertex_info.view * world).z;
    mat3 basis = mat3(transform);
    fragNormal = abs(determinant(basis)) > 0.000001
        ? transpose(inverse(basis)) * vertexNormal
        : basis * vertexNormal;
}

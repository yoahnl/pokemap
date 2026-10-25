#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

out vec4 outColor;

#include "point_shadow_sampling.glsl"

void main() {
    float depth = pointShadowCasterDepth();
    vec4 packed = fract(depth * vec4(1.0, 255.0, 65025.0, 16581375.0));
    packed -= packed.yzww * vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
    outColor = packed;
}

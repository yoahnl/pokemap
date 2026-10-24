#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

out vec4 outColor;

#include "pixel_sampling.glsl"

void main() {
    vec4 color = samplePixelColor();
    if (material.alphaMode == 0.0 && color.a < material.alphaCutoff) discard;
    if (material.alphaMode == 2.0 && color.a * material.albedoColor.a * fragColor.a < material.alphaCutoff) discard;
    float depth = clamp(gl_FragCoord.z, 0.0, 0.999999);
    vec4 packed = fract(depth * vec4(1.0, 255.0, 65025.0, 16581375.0));
    packed -= packed.yzww * vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
    outColor = packed;
}

#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;
in float fragViewDepth;
out vec4 outColor;

#include "pixel_sampling.glsl"

uniform CameraDepth {
    vec4 options;
} camera_depth;

void main() {
    vec4 color = samplePixelColor();
    float alpha = color.a * material.albedoColor.a * fragColor.a;
    if (material.alphaMode == 0.0 && color.a < material.alphaCutoff) discard;
    if (material.alphaMode == 2.0 && alpha < material.alphaCutoff) discard;
    if (material.alphaMode == 3.0 && alpha < 0.1) discard;
    float depth = clamp(fragViewDepth / camera_depth.options.x, 0.0, 0.999999);
    vec3 packed = fract(depth * vec3(1.0, 255.0, 65025.0));
    packed -= packed.yzz * vec3(1.0 / 255.0, 1.0 / 255.0, 0.0);
    outColor = vec4(packed, 1.0);
}

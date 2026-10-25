#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

out vec4 outColor;

#include "pixel_sampling.glsl"

#if defined(IMPELLER_TARGET_METAL)
uniform DepthSamples {
    vec4 options;
} depth_samples;
#endif

void main() {
    vec4 color = samplePixelColor();
    if (material.alphaMode == 0.0 && color.a < material.alphaCutoff) discard;
    if (material.alphaMode == 2.0 && color.a * material.albedoColor.a * fragColor.a < material.alphaCutoff) discard;
    float depth = gl_FragCoord.z;
    outColor = vec4(0.0);
    float sampleDepth = clamp(depth, 0.000001, 1.0);
#if defined(IMPELLER_TARGET_METAL)
    sampleDepth *= depth_samples.options.x;
    outColor = vec4(gl_SampleID == 0 ? sampleDepth : 0.0, gl_SampleID == 1 ? sampleDepth : 0.0, gl_SampleID == 2 ? sampleDepth : 0.0, gl_SampleID == 3 ? sampleDepth : 0.0);
#else
    outColor = vec4(sampleDepth * 0.25);
#endif
}

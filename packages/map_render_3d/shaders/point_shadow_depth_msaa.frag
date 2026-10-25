#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

out vec4 outColor;

#include "point_shadow_sampling.glsl"

#if defined(IMPELLER_TARGET_METAL)
uniform DepthSamples {
    vec4 options;
} depth_samples;
#endif

void main() {
    float depth = pointShadowCasterDepth();
    outColor = vec4(0.0);
    float sampleDepth = clamp(depth, 0.000001, 1.0);
#if defined(IMPELLER_TARGET_METAL)
    sampleDepth *= depth_samples.options.x;
    outColor = vec4(gl_SampleID == 0 ? sampleDepth : 0.0, gl_SampleID == 1 ? sampleDepth : 0.0, gl_SampleID == 2 ? sampleDepth : 0.0, gl_SampleID == 3 ? sampleDepth : 0.0);
#else
    outColor = vec4(sampleDepth * 0.25);
#endif
}

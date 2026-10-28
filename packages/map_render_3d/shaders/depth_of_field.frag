#version 460 core

in vec2 textureCoordinate;
out vec4 outColor;
uniform sampler2D sceneTexture;
uniform sampler2D depthTexture;
#include <flame_3d/depth_attachment.glsl>

uniform DepthOfField {
    vec4 focus;
    vec4 viewport;
} depth_of_field;

float depthAt(vec2 uv) {
    vec2 dimensions = depth_of_field.viewport.xy;
    vec2 sampleUv = (floor(clamp(uv, vec2(0.0), vec2(0.999999)) * dimensions) + 0.5) / dimensions;
    vec3 encoded = texture(depthTexture, sampleUv).rgb;
    float depth = dot(encoded, vec3(1.0, 1.0 / 255.0, 1.0 / 65025.0));
    return all(equal(encoded, vec3(1.0)))
        ? depth * depth_of_field.focus.w
        : min(depth * depthAttachmentRange, depth_of_field.focus.w * 0.999999);
}

float defocus(float depth) {
    return smoothstep(depth_of_field.focus.y,
        depth_of_field.focus.y + depth_of_field.viewport.z,
        abs(depth - depth_of_field.focus.x));
}

void main() {
    vec2 uv = textureCoordinate;
    vec4 sharp = texture(sceneTexture, uv);
    float centerDepth = depthAt(uv);
    float radius = defocus(centerDepth) * depth_of_field.focus.z;
    if (radius < 0.35) {
        outColor = sharp;
        return;
    }
    vec4 total = sharp;
    float weights = 1.0;
    for (int ring = 1; ring <= 3; ring++) {
        for (int tap = 0; tap < 12; tap++) {
            float angle = (float(tap) + float(ring) * 0.37) * 0.5235987756;
            vec2 offset = vec2(cos(angle), sin(angle)) * radius * float(ring) / 3.0;
            vec2 sampleUv = clamp(uv + offset / depth_of_field.viewport.xy, vec2(0.0), vec2(1.0));
            float sampleDepth = depthAt(sampleUv);
            float tolerance = max(1.0, depth_of_field.focus.y * 0.5);
            float weight = 1.0 - smoothstep(tolerance, tolerance * 2.0, abs(sampleDepth - centerDepth));
            total += texture(sceneTexture, sampleUv) * weight;
            weights += weight;
        }
    }
    outColor = total / weights;
}

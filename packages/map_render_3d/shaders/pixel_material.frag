#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

out vec4 outColor;

#include "pixel_sampling.glsl"

uniform sampler2D shadowTexture;
uniform Shadow {
    mat4 worldToLight;
    vec4 options;
    vec4 receiverHeight;
} shadow;

float shadowVisibility() {
    vec4 projected = shadow.worldToLight * vec4(fragPosition, 1.0);
    vec3 coord = projected.xyz / projected.w;
    vec2 uv = vec2(coord.x * 0.5 + 0.5, 0.5 - coord.y * 0.5);
    if (coord.z < 0.0 || coord.z > 1.0 || any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return 1.0;
    float visibility = 0.0;
    float resolution = shadow.options.z;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 sampleUv = (floor(uv * resolution) + vec2(x, y) + 0.5) / resolution;
            if (any(lessThan(sampleUv, vec2(0.0))) || any(greaterThan(sampleUv, vec2(1.0)))) {
                visibility += 1.0;
            } else {
                vec4 packed = texture(shadowTexture, sampleUv);
                float stored = dot(packed, vec4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0));
                visibility += coord.z - shadow.options.y <= stored ? 1.0 : 0.0;
            }
        }
    }
    return visibility / 9.0;
}

void main() {
    vec4 color = samplePixelColor();
    outColor = color * material.albedoColor * fragColor;
    if (material.lightingOptions.x > 0.5) {
        vec3 normal = vec3(0.0, 1.0, 0.0);
        if (material.lightingOptions.y > 0.5 && dot(fragNormal, fragNormal) > 0.000001) {
            normal = normalize(fragNormal);
        }
        float diffuse = max(dot(normal, material.lightingDirection.xyz), 0.0);
        vec3 lighting = material.lightingAmbient.rgb + material.lightingSun.rgb * diffuse;
        outColor.rgb *= mix(vec3(1.0), lighting, material.lightingOptions.z);
    }
    if (shadow.options.x > 0.5 && fragPosition.y >= shadow.receiverHeight.x && fragPosition.y <= shadow.receiverHeight.y) {
        outColor.rgb *= 1.0 - shadow.options.w * (1.0 - shadowVisibility());
    }
    if (material.alphaMode == 0.0) {
        if (color.a < material.alphaCutoff) discard;
        outColor.rgb *= material.albedoColor.a * fragColor.a;
    } else if (material.alphaMode == 3.0) {
        outColor.rgb *= outColor.a;
    } else {
        if (material.alphaMode == 2.0 && outColor.a < material.alphaCutoff) discard;
        outColor.a = 1.0;
    }
}

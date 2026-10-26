#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;
in float fragViewDepth;

out vec4 outColor;

#include "pixel_sampling.glsl"
#include "point_shadow_cube.glsl"
#include "shadow_filter.glsl"

uniform sampler2D pointShadowTexture;
uniform PointShadows {
    vec4 options;
} point_shadows;

uniform sampler2D shadowTexture;
uniform Shadow {
    mat4 worldToLight;
    vec4 options;
    vec4 receiverHeight;
    vec4 samplePosition;
    vec4 origin;
    vec4 coverage;
} shadow;

uniform Environment {
    vec4 tint;
    vec4 options;
    vec4 samplePosition;
    vec4 pointPositionRadius[4];
    vec4 pointColorIntensity[4];
    vec4 fireflyPositionRadius[2];
    vec4 fireflyColorIntensity[2];
} environment;

uniform Atmosphere {
    vec4 options;
    vec4 windowColor;
    vec4 windowRects[8];
} atmosphere;

uniform Presentation {
    vec4 fogColor;
    vec4 depthRange;
    vec4 weatherFog;
    vec4 weatherImpacts;
    vec4 manualFog;
} presentation;

float sampledShadowVisibility(vec4 packed, float reference, bool multisampled) {
    if (multisampled) {
        vec4 depths = packed * 4.0;
        vec4 covered = step(vec4(0.0000005), depths);
        return dot(mix(vec4(1.0), step(vec4(reference), depths), covered), vec4(0.25));
    }
    float stored = dot(packed, vec4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0));
    return reference <= stored ? 1.0 : 0.0;
}

float pointShadowComparison(vec2 pixel, vec2 tile, float resolution, float rows, int face, vec3 delta, vec3 receiverNormal, float radius, float bias) {
    vec2 faceUv = (pixel + 0.5) / resolution;
    vec2 sampleUv = (tile + faceUv) / vec2(3.0, rows);
    vec3 ray = pointShadowRay(faceUv, face);
    float denominator = dot(receiverNormal, ray);
    float planeDistance = abs(denominator) > 0.000001 ? dot(receiverNormal, delta) / denominator : -1.0;
    float expected = planeDistance > 0.0 ? min(radius, planeDistance) : length(delta);
    float reference = max(0.0, expected - bias) / radius;
    return sampledShadowVisibility(texture(pointShadowTexture, sampleUv), reference, point_shadows.options.x > 1.5 && point_shadows.options.x < 2.5);
}

float pointVisibility(vec3 delta, vec3 receiverNormal, int lightIndex, float radius) {
    if (point_shadows.options.x < 0.5 || dot(delta, delta) < 0.000001) return 1.0;
    int face = pointShadowFace(delta);
    vec2 uv = pointShadowFaceUv(delta, face);
    float resolution = point_shadows.options.y;
    float rows = point_shadows.options.z * 2.0;
    vec2 tile = vec2(float(face % 3), float(face / 3 + lightIndex * 2));
    float distance = length(delta);
    float cosine = clamp(abs(dot(receiverNormal, delta / distance)), 0.0, 1.0);
    float footprint = 2.0 * distance / resolution;
    float bias = min(min(point_shadows.options.w, radius * 0.005), 0.001 + footprint * (0.1 + 0.1 * (1.0 - cosine)));
    float visibility = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 pixel = clamp(floor(uv * resolution) + vec2(x, y), vec2(0.0), vec2(resolution - 1.0));
            float weight = float((x == 0 ? 2 : 1) * (y == 0 ? 2 : 1));
            if (point_shadows.options.x > 2.5) {
                for (int sy = 0; sy < 2; sy++) {
                    for (int sx = 0; sx < 2; sx++) {
                        vec2 subPixel = pixel + vec2(float(sx), float(sy)) * 0.5 - 0.25;
                        visibility += pointShadowComparison(subPixel, tile, resolution, rows, face, delta, receiverNormal, radius, bias) * weight * 0.25;
                    }
                }
            } else {
                visibility += pointShadowComparison(pixel, tile, resolution, rows, face, delta, receiverNormal, radius, bias) * weight;
            }
        }
    }
    return visibility / 16.0;
}

float shadowComparison(vec2 pixel, float reference, vec2 receiverPixel, vec2 depthGradient) {
    float resolution = shadow.options.z;
    if (any(lessThan(pixel, vec2(0.0))) || any(greaterThanEqual(pixel, vec2(resolution)))) return 1.0;
    if (shadow.options.x > 2.5) {
        float visibility = 0.0;
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 2; x++) {
                vec2 subPixel = pixel + vec2(float(x), float(y)) * 0.5 - 0.25;
                vec4 packed = texture(shadowTexture, (subPixel + 0.5) / resolution);
                visibility += sampledShadowVisibility(packed, reference + dot(subPixel - receiverPixel, depthGradient), false);
            }
        }
        return visibility * 0.25;
    }
    vec4 packed = texture(shadowTexture, (pixel + 0.5) / resolution);
    return sampledShadowVisibility(packed, reference + dot(pixel - receiverPixel, depthGradient), shadow.options.x > 1.5);
}

float interpolatedShadowComparison(vec2 pixel, float reference, vec2 receiverPixel, vec2 depthGradient) {
    vec2 base = floor(pixel);
    vec2 fraction = fract(pixel);
    return mix(
        mix(shadowComparison(base, reference, receiverPixel, depthGradient), shadowComparison(base + vec2(1.0, 0.0), reference, receiverPixel, depthGradient), fraction.x),
        mix(shadowComparison(base + vec2(0.0, 1.0), reference, receiverPixel, depthGradient), shadowComparison(base + vec2(1.0), reference, receiverPixel, depthGradient), fraction.x),
        fraction.y
    );
}

float shadowVisibility(vec3 samplePosition, vec3 receiverNormal) {
    vec4 projected = shadow.worldToLight * vec4(samplePosition - shadow.origin.xyz, 1.0);
    vec3 coord = projected.xyz / projected.w;
    vec2 uv = vec2(coord.x * 0.5 + 0.5, 0.5 - coord.y * 0.5);
    if (coord.z < 0.0 || coord.z > 1.0 || any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return 1.0;
    ivec2 cell = clamp(ivec2(floor(uv * 8.0)), ivec2(0), ivec2(7));
    int cellIndex = cell.y * 8 + cell.x;
    uint covered = uint(shadow.coverage[cellIndex / 16]);
    if ((covered & (1u << uint(cellIndex % 16))) == 0u) return 1.0;
    float resolution = shadow.options.z;
    float reference = coord.z - shadow.options.y;
    vec2 pixel = uv * resolution - 0.5;
    vec3 lightX = vec3(shadow.worldToLight[0].x, shadow.worldToLight[1].x, shadow.worldToLight[2].x);
    vec3 lightY = vec3(shadow.worldToLight[0].y, shadow.worldToLight[1].y, shadow.worldToLight[2].y);
    vec3 lightZ = vec3(shadow.worldToLight[0].z, shadow.worldToLight[1].z, shadow.worldToLight[2].z);
    vec3 plane = vec3(dot(receiverNormal, lightX) / dot(lightX, lightX), dot(receiverNormal, lightY) / dot(lightY, lightY), dot(receiverNormal, lightZ) / dot(lightZ, lightZ));
    vec2 depthGradient = abs(plane.z) > 0.000001 ? vec2(-plane.x, plane.y) * (2.0 / (resolution * plane.z)) : vec2(0.0);
    if (shadow.receiverHeight.z == 0.0) return shadowComparison(floor(uv * resolution), reference, pixel, depthGradient);
    float radius = max(0.5, shadow.receiverHeight.z);
    vec2 first = floor(pixel - radius + 0.5);
    int pairs = int(ceil((2.0 * radius + 1.0) / 2.0));
    float visibility = 0.0;
    for (int y = 0; y < 9; y++) {
        if (y >= pairs) break;
        float row = first.y + float(y * 2);
        float offsetY = row - pixel.y;
        float weightY = shadowPairWeight(offsetY, radius);
        if (weightY <= 0.0) continue;
        float sampleY = row + shadowPairOffset(offsetY, radius);
        for (int x = 0; x < 9; x++) {
            if (x >= pairs) break;
            float column = first.x + float(x * 2);
            float offsetX = column - pixel.x;
            float weightX = shadowPairWeight(offsetX, radius);
            if (weightX <= 0.0) continue;
            float sampleX = column + shadowPairOffset(offsetX, radius);
            visibility += interpolatedShadowComparison(vec2(sampleX, sampleY), reference, pixel, depthGradient) * weightX * weightY;
        }
    }
    return visibility;
}

void main() {
    vec3 receiverNormal = cross(dFdx(fragPosition), dFdy(fragPosition));
    receiverNormal = dot(receiverNormal, receiverNormal) > 0.000000000001 ? normalize(receiverNormal) : vec3(0.0, 1.0, 0.0);
    if (environment.samplePosition.w > 0.5) receiverNormal = vec3(0.0, 1.0, 0.0);
    vec4 color = samplePixelColor();
    outColor = color * material.albedoColor * (material.alphaMode == 4.0 ? vec4(1.0) : fragColor);
    if (atmosphere.options.z < 0.5 && material.lightingOptions.x > 0.5) {
        vec3 normal = vec3(0.0, 1.0, 0.0);
        if (material.lightingOptions.y > 0.5 && dot(fragNormal, fragNormal) > 0.000001) {
            normal = normalize(fragNormal);
        }
        float diffuse = max(dot(normal, material.lightingDirection.xyz), 0.0);
        float sunVisibility = 1.0;
        vec3 shadowPosition = shadow.samplePosition.w > 0.5 ? shadow.samplePosition.xyz : fragPosition;
        if (shadow.options.x > 0.5 && shadowPosition.y >= shadow.receiverHeight.x && shadowPosition.y <= shadow.receiverHeight.y) {
            sunVisibility = 1.0 - shadow.options.w * (1.0 - shadowVisibility(shadowPosition, receiverNormal));
        }
        vec3 lighting = material.lightingAmbient.rgb + material.lightingSun.rgb * diffuse * sunVisibility;
        outColor.rgb *= mix(vec3(1.0), lighting, material.lightingOptions.z);
    }
    if (atmosphere.options.z < 0.5 && environment.options.x > 0.5) {
        vec3 samplePosition = environment.samplePosition.w > 0.5 ? environment.samplePosition.xyz : fragPosition;
        vec3 localLight = vec3(0.0);
        for (int index = 0; index < 4; index++) {
            if (float(index) >= environment.options.y) break;
            vec3 delta = samplePosition - environment.pointPositionRadius[index].xyz;
            float radius = environment.pointPositionRadius[index].w;
            float attenuation = max(0.0, 1.0 - dot(delta, delta) / (radius * radius));
            attenuation *= attenuation;
            float visibility = attenuation > 0.0 ? pointVisibility(delta, receiverNormal, index, radius) : 1.0;
            localLight += environment.pointColorIntensity[index].rgb * environment.pointColorIntensity[index].w * attenuation * visibility;
        }
        for (int index = 0; index < int(environment.options.z); index++) {
            vec3 delta = samplePosition - environment.fireflyPositionRadius[index].xyz;
            float radius = environment.fireflyPositionRadius[index].w;
            float attenuation = max(0.0, 1.0 - dot(delta, delta) / (radius * radius));
            localLight += environment.fireflyColorIntensity[index].rgb * environment.fireflyColorIntensity[index].w * attenuation * attenuation;
        }
        vec3 baseColor = color.rgb * material.albedoColor.rgb * (material.alphaMode == 4.0 ? vec3(1.0) : fragColor.rgb);
        outColor.rgb = outColor.rgb * environment.tint.rgb + baseColor * localLight;
    }
    if (atmosphere.options.x > 0.0) {
        vec2 pixelWorld = floor(fragPosition.xz * 32.0) / 32.0;
        float t = atmosphere.options.y;
        float wave = sin(pixelWorld.x * 7.0 + pixelWorld.y * 3.5 + t * 1.4);
        float crossWave = sin(pixelWorld.x * 2.3 - pixelWorld.y * 8.0 - t * 0.85);
        float glint = pow(max(0.0, wave * crossWave), 12.0);
        float ripple = (wave + crossWave) * 0.025;
        outColor.rgb = max(vec3(0.0), outColor.rgb + vec3(ripple * 0.6, ripple, ripple * 1.15) * atmosphere.options.x);
        outColor.rgb += vec3(0.13, 0.20, 0.22) * glint * atmosphere.options.x;
    }
    if (atmosphere.windowColor.w > 0.0) {
        float mask = 0.0;
        vec2 windowUv = samplePixelUv();
        for (int i = 0; i < 8; i++) {
            if (float(i) >= atmosphere.options.w) break;
            vec4 rect = atmosphere.windowRects[i];
            mask = max(mask, step(rect.x, windowUv.x) * step(rect.y, windowUv.y) * step(windowUv.x, rect.z) * step(windowUv.y, rect.w));
        }
        vec3 litGlass = atmosphere.windowColor.rgb * (0.72 + 0.28 * color.rgb);
        outColor.rgb = mix(outColor.rgb, litGlass, clamp(mask * atmosphere.windowColor.w, 0.0, 1.0));
    }
    if (presentation.weatherImpacts.x > 0.0 && abs(receiverNormal.y) > 0.7) {
        vec2 cell = floor(fragPosition.xz * 1.8);
        float seed = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
        float phase = fract(presentation.weatherImpacts.z * presentation.weatherImpacts.y + seed);
        vec2 center = vec2(fract(seed * 13.17), fract(seed * 39.43)) * 0.6 + 0.2;
        float radius = length(fract(fragPosition.xz * 1.8) - center);
        float ring = 1.0 - smoothstep(0.015, 0.055, abs(radius - phase * 0.38));
        float ripple = ring * (1.0 - phase) * smoothstep(0.0, 0.08, phase);
        ripple *= step(seed, presentation.weatherImpacts.x) * presentation.weatherImpacts.x;
        outColor.rgb = mix(outColor.rgb, outColor.rgb * 0.75 + vec3(0.18, 0.23, 0.26) * environment.tint.rgb,
                           ripple * 0.65);
    }
    if (presentation.fogColor.w > 0.0 || presentation.manualFog.z > 0.0) {
        float haze = smoothstep(presentation.depthRange.x, presentation.depthRange.y, fragViewDepth) * presentation.fogColor.w;
        if (presentation.weatherFog.w > 0.0) {
            float time = presentation.depthRange.z;
            vec2 drift = fragPosition.xz * 0.32 - presentation.weatherFog.xy * time * 0.035;
            float wave = sin(drift.x + sin(drift.y * 0.73 + time * 0.07))
                       * sin(drift.y * 0.91 - time * 0.045);
            float low = exp(-max(0.0, fragPosition.y - presentation.weatherFog.z) * 0.38);
            float density = (0.95 + wave * 0.4) * (0.55 + low * 0.45);
            float bank = low * (0.5 + wave * 0.5) * presentation.weatherFog.w * 0.18;
            haze = 1.0 - exp(-(haze + bank) * (1.0 + presentation.weatherFog.w * 2.0) * density);
        }
        float manual = smoothstep(presentation.manualFog.x, presentation.manualFog.y, fragViewDepth) * presentation.manualFog.z;
        haze = 1.0 - (1.0 - haze) * (1.0 - manual);
        outColor.rgb = mix(outColor.rgb, presentation.fogColor.rgb, haze);
    }
    if (material.alphaMode == 0.0) {
        if (color.a < material.alphaCutoff) discard;
        outColor.rgb *= material.albedoColor.a * fragColor.a;
    } else if (material.alphaMode == 3.0) {
        outColor.rgb *= outColor.a;
    } else if (material.alphaMode != 4.0) {
        if (material.alphaMode == 2.0 && outColor.a < material.alphaCutoff) discard;
        outColor.a = 1.0;
    }
}

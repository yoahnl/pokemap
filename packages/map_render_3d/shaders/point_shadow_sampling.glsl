#include "pixel_sampling.glsl"
#include "point_shadow_cube.glsl"

uniform PointDepth {
    vec4 positionRadius;
    vec4 tile;
} point_depth;

float pointShadowCasterDepth() {
    vec3 delta = fragPosition - point_depth.positionRadius.xyz;
    if (pointShadowFace(delta) != int(point_depth.tile.z)) discard;
    float distance = length(delta) / point_depth.positionRadius.w;
    if (distance >= 1.0) discard;
    vec4 color = samplePixelColor();
    if (material.alphaMode == 0.0 && color.a < material.alphaCutoff) discard;
    if (material.alphaMode == 2.0 && color.a * material.albedoColor.a * fragColor.a < material.alphaCutoff) discard;
    return clamp(distance, 0.0, 0.999999);
}

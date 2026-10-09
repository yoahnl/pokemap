#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

out vec4 outColor;

uniform sampler2D albedoTexture;
uniform Material {
    vec4 albedoColor;
    vec4 uvRect;
    vec4 uvTransformU;
    vec4 uvTransformV;
    vec2 textureDimensions;
    vec2 wrapModes;
    float alphaMode;
    float alphaCutoff;
} material;

float wrapCoordinate(float uv, float mode) {
    if (mode == 33071.0) return clamp(uv, 0.0, 1.0);
    if (mode == 33648.0) return 1.0 - abs(mod(uv, 2.0) - 1.0);
    return fract(uv);
}

void main() {
    vec2 uv = material.uvRect.xy + fragTexCoord * material.uvRect.zw;
    uv = vec2(dot(material.uvTransformU.xyz, vec3(uv, 1.0)), dot(material.uvTransformV.xyz, vec3(uv, 1.0)));
    uv = vec2(wrapCoordinate(uv.x, material.wrapModes.x), wrapCoordinate(uv.y, material.wrapModes.y));
    vec2 pixel = clamp(floor(uv * material.textureDimensions), vec2(0.0), material.textureDimensions - 1.0);
    vec4 color = texture(albedoTexture, (pixel + 0.5) / material.textureDimensions);
    outColor = color * material.albedoColor * fragColor;
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

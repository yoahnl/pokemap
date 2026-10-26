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
    vec4 lightingAmbient;
    vec4 lightingSun;
    vec4 lightingDirection;
    vec4 lightingOptions;
} material;

float wrapCoordinate(float uv, float mode) {
    if (mode == 33071.0) return clamp(uv, 0.0, 1.0);
    if (mode == 33648.0) return 1.0 - abs(mod(uv, 2.0) - 1.0);
    return fract(uv);
}

vec2 samplePixelUv() {
    vec2 uv = material.uvRect.xy + fragTexCoord * material.uvRect.zw;
    uv = vec2(dot(material.uvTransformU.xyz, vec3(uv, 1.0)), dot(material.uvTransformV.xyz, vec3(uv, 1.0)));
    return vec2(wrapCoordinate(uv.x, material.wrapModes.x), wrapCoordinate(uv.y, material.wrapModes.y));
}

vec4 samplePixelColor() {
    vec2 uv = samplePixelUv();
    vec2 pixel = clamp(floor(uv * material.textureDimensions), vec2(0.0), material.textureDimensions - 1.0);
    return texture(albedoTexture, (pixel + 0.5) / material.textureDimensions);
}

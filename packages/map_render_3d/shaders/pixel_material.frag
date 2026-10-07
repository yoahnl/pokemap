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
    vec2 textureDimensions;
} material;

void main() {
    vec2 uv = material.uvRect.xy + fragTexCoord * material.uvRect.zw;
    vec2 pixel = mod(floor(uv * material.textureDimensions), material.textureDimensions);
    vec4 color = texture(albedoTexture, (pixel + 0.5) / material.textureDimensions);
    if (color.a < 0.1) discard;
    outColor = color * material.albedoColor * fragColor;
    outColor.rgb *= material.albedoColor.a * fragColor.a;
}

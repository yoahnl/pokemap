#version 460 core

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;
in float fragViewDepth;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outDepth;

#include <flame_3d/depth_attachment.glsl>

uniform sampler2D albedoTexture;

uniform Material {
  vec4 albedoColor;
} material;

void main() {
  vec4 texColor = texture(albedoTexture, fragTexCoord);
  outColor = texColor * material.albedoColor;
  outDepth = encodeDepthAttachment(fragViewDepth, texColor.a < 0.1 ? 0.0 : 1.0);
}

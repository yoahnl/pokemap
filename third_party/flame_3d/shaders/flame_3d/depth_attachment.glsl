const float depthAttachmentRange = 4096.0;

vec4 encodeDepthAttachment(float viewDepth, float coverage) {
    float depth = clamp(viewDepth / depthAttachmentRange, 0.0, 0.999999);
    vec3 packed = fract(depth * vec3(1.0, 255.0, 65025.0));
    packed -= packed.yzz * vec3(1.0 / 255.0, 1.0 / 255.0, 0.0);
    return vec4(packed, coverage);
}

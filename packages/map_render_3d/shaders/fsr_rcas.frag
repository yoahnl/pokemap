#version 460 core

in vec2 textureCoordinate;
out vec4 outColor;
uniform sampler2D inputTexture;
uniform Rcas {
    vec4 options;
} rcas;

vec4 rcasTap(vec2 texel) {
    vec2 size = rcas.options.xy;
    return texture(inputTexture, (clamp(texel, vec2(0.0), size - 1.0) + 0.5) / size);
}

void main() {
    vec2 sp = floor(textureCoordinate * rcas.options.xy);
    vec3 b = rcasTap(sp + vec2(0.0, -1.0)).rgb;
    vec3 d = rcasTap(sp + vec2(-1.0, 0.0)).rgb;
    vec4 center = rcasTap(sp);
    vec3 e = center.rgb;
    vec3 f = rcasTap(sp + vec2(1.0, 0.0)).rgb;
    vec3 h = rcasTap(sp + vec2(0.0, 1.0)).rgb;
    vec3 mn4 = min(min(b, d), min(f, h));
    vec3 mx4 = max(max(b, d), max(f, h));
    vec3 hitMin = min(mn4, e) / max(4.0 * mx4, vec3(1.0e-6));
    vec3 hitMax = (1.0 - max(mx4, e)) / min(4.0 * mn4 - 4.0, vec3(-1.0e-6));
    vec3 lobeRGB = max(-hitMin, hitMax);
    float lobe = max(-(0.25 - 1.0 / 16.0), min(max(max(lobeRGB.r, lobeRGB.g), lobeRGB.b), 0.0)) * rcas.options.z;
    vec3 color = (lobe * (b + d + h + f) + e) / (4.0 * lobe + 1.0);
    outColor = vec4(clamp(color, vec3(0.0), vec3(center.a)), center.a);
}
